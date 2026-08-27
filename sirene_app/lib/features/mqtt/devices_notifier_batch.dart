part of 'mqtt_providers.dart';

mixin _DevicesNotifierBatch on _DevicesNotifierBase {
  int _resolvedApprovedCount(DeviceInfo? device, TestResultMessage? test) {
    final fromTest = test?.aprovadosNoLote ?? 0;
    final fromFirmware = device?.firmwareAprovados ?? 0;
    return fromTest > fromFirmware ? fromTest : fromFirmware;
  }

  @override
  Future<void> _maybeAutoEndBatch(String deviceId, {TestResultMessage? test}) async {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null) return;
    if (test != null && batch.numeroOp != test.numeroOp) return;
    if (batch.quantidadeTotal <= 0) return;

    final approved = _resolvedApprovedCount(device, test);
    if (approved < batch.quantidadeTotal) return;
    if (_autoEndBatchSent.contains(deviceId)) return;

    _autoEndBatchSent.add(deviceId);
    final db = _ref.read(databaseProvider);
    await _syncMarkingForOp(db, batch.numeroOp, since: device?.batchStartedAt);
    await _ensureMarkServerForOp();

    // Firmware ainda está em TESTING por alguns ms após publicar o resultado.
    for (var i = 0; i < 15; i++) {
      if (state[deviceId]?.estado != DeviceFsmState.testing) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    final rejection = await sendEndBatch(deviceId);
    if (rejection == null) {
      _ref.read(autoBatchEndedProvider.notifier).state = (
        deviceId: deviceId,
        numeroOp: batch.numeroOp,
      );
    } else {
      _autoEndBatchSent.remove(deviceId);
    }
  }

  @override
  void _advanceBatchSequencial(String deviceId, TestResultMessage test) {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null || batch.numeroOp != test.numeroOp) return;
    device!.activeBatch = batch.copyWith(proximoSequencial: test.sequencial + 1);
  }

  void setActiveBatch(String deviceId, BatchConfig batch) {
    final device = _getOrCreate(deviceId);
    device.activeBatch = batch;
    device.batchStartedAt = DateTime.now();
    device.firmwareAprovados = null;
    device.firmwareAprovadosOp = null;
    device.firmwareProximoSequencial = batch.proximoSequencial;
    device.lastTestResult = null;
    device.awaitingMqttResult = false;
    device.lastRejection = null;
    _cancelVerdictWatchdog(deviceId);
    _batchStartedAt[deviceId] = device.batchStartedAt!;
    state = {...state};
  }

  void clearActiveBatch(String deviceId) {
    final device = state[deviceId];
    if (device != null) {
      device.activeBatch = null;
      device.batchStartedAt = null;
      device.firmwareAprovados = null;
      device.firmwareAprovadosOp = null;
      device.firmwareProximoSequencial = null;
      device.awaitingMqttResult = false;
      device.lastHeartbeat = null;
      _cancelVerdictWatchdog(deviceId);
      state = {...state};
    }
  }

  /// Publica SET_BATCH e retorna motivo de rejeição, ou null se aceito.
  Future<String?> sendSetBatch(String deviceId, BatchConfig batch) async {
    if (_ref.read(demoModeProvider)) {
      return _sendSetBatchDemo(deviceId, batch);
    }

    final service = _ref.read(mqttServiceProvider);
    await _publishForDevice(deviceId, batch.toSetBatchJson());
    final rejection = service.currentState == AppMqttConnectionState.connected
        ? await waitForRejection(deviceId)
        : null;
    if (rejection != null) return rejection;

    if (service.currentState == AppMqttConnectionState.connected) {
      final configured = await waitForBatchConfigured(deviceId);
      if (!configured) {
        return 'batch_sem_confirmacao';
      }
    }

    _ref.read(retestModeProvider.notifier).state = batch.modoReteste;
    _autoEndBatchSent.remove(deviceId);
    setActiveBatch(deviceId, batch);
    _setDeviceEstado(deviceId, DeviceFsmState.batchReady);
    final startedAt = _batchStartedAt[deviceId] ?? DateTime.now();
    await _ref.read(firestoreSyncServiceProvider).enqueueBatch(
      batch: batch,
      deviceId: deviceId,
      status: 'active',
      startedAt: startedAt,
    );
    return null;
  }

  Future<String?> _sendSetBatchDemo(String deviceId, BatchConfig batch) async {
    _ref.read(retestModeProvider.notifier).state = batch.modoReteste;
    _autoEndBatchSent.remove(deviceId);
    ensureDemoDevice(deviceId);
    setActiveBatch(deviceId, batch);
    _setDeviceEstado(deviceId, DeviceFsmState.batchReady);
    return null;
  }

  /// Alterna modo reteste no firmware sem alterar demais parâmetros do lote.
  Future<String?> syncRetestMode(String deviceId, bool modoReteste) async {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null) return 'Sem lote ativo';

    final updated = batch.copyWith(modoReteste: modoReteste);
    if (_ref.read(demoModeProvider)) {
      _ref.read(retestModeProvider.notifier).state = modoReteste;
      setActiveBatch(deviceId, updated);
      return null;
    }

    final service = _ref.read(mqttServiceProvider);
    await _publishForDevice(deviceId, updated.toSetBatchJson());
    final rejection = service.currentState == AppMqttConnectionState.connected
        ? await waitForRejection(deviceId)
        : null;
    if (rejection != null) return rejection;

    _ref.read(retestModeProvider.notifier).state = modoReteste;
    setActiveBatch(deviceId, updated);
    return null;
  }

  Future<bool> waitForState(
    String deviceId,
    DeviceFsmState expected, {
    Duration timeout = const Duration(seconds: 35),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final device = state[deviceId];
      if (device?.estado == expected) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  /// Lock OP, sync cloud, flush labels/marking — shared by END_BATCH and firmware `encerrado`.
  @override
  Future<void> _finalizeBatchLocally(String deviceId) async {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    final startedAt = _batchStartedAt[deviceId];

    if (batch != null) {
      final db = _ref.read(databaseProvider);
      await _syncMarkingForOp(db, batch.numeroOp, since: device?.batchStartedAt);
      await _ensureMarkServerForOp();
      await db.lockOp(batch.numeroOp);
    }
    if (batch != null && startedAt != null && !_ref.read(demoModeProvider)) {
      await _ref.read(firestoreSyncServiceProvider).enqueueBatch(
        batch: batch,
        deviceId: deviceId,
        status: 'completed',
        startedAt: startedAt,
        endedAt: DateTime.now(),
        aprovados: device?.lastTestResult?.aprovadosNoLote,
      );
    }
    _batchStartedAt.remove(deviceId);
    _autoEndBatchSent.remove(deviceId);
    _ref.read(retestModeProvider.notifier).state = false;
    clearActiveBatch(deviceId);
    _setDeviceEstado(deviceId, DeviceFsmState.idle);
  }

  /// Publica END_BATCH e retorna motivo de rejeição, ou null se aceito.
  Future<String?> sendEndBatch(String deviceId) async {
    if (_ref.read(demoModeProvider)) {
      _ref.read(demoAutoPlayProvider.notifier).state = false;
      await _finalizeBatchLocally(deviceId);
      return null;
    }

    final service = _ref.read(mqttServiceProvider);
    if (service.currentState != AppMqttConnectionState.connected) {
      return 'mqtt_desconectado';
    }

    await _publishForDevice(deviceId, {'cmd': 'END_BATCH'});
    final rejection = await waitForRejection(deviceId);
    if (rejection != null) return rejection;

    await _finalizeBatchLocally(deviceId);
    return null;
  }
}
