import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/mqtt_topics.dart';
import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/app_log.dart';
import '../../core/utils/device_stale.dart';
import '../cloud/auth/auth_providers.dart';
import '../cloud/sync/sync_providers.dart';
import '../labels/label_printer.dart';
import '../labels/label_print_logic.dart';
import '../labels/marking_providers.dart';
import '../labels/serial_marking_backend.dart';
import '../labels/zpl_generator.dart';
import '../serial/itf_check_digit.dart';
import 'message_pump.dart';
import 'mqtt_status_parser.dart';
import '../batch/batch_live_providers.dart';
import '../batch/batch_serial_logic.dart';
import '../dashboard/dashboard_providers.dart';
import '../demo/demo_constants.dart';
import '../demo/demo_providers.dart';
import '../ensaio/ensaio_config.dart';
import '../ensaio/ensaio_providers.dart';
import '../operators/operators_provider.dart';
import 'models/mqtt_messages.dart';
import 'mqtt_parser.dart';
import 'mqtt_connection_config.dart';
import 'mqtt_service.dart';

export '../../core/providers/core_providers.dart'
    show appConfigProvider, databaseProvider, sharedPreferencesProvider;

final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(service.dispose);
  return service;
});

final mqttConnectionStateProvider = StreamProvider<AppMqttConnectionState>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.connectionState;
});

/// Estado MQTT efetivo — evita "Desconectado" enquanto o stream ainda não emitiu.
AppMqttConnectionState resolveMqttConnectionDisplayState(
  AsyncValue<AppMqttConnectionState> mqttAsync,
  AppMqttConnectionState serviceState,
) {
  return mqttAsync.when(
    data: (state) => state,
    loading: () => serviceState,
    error: (_, __) => AppMqttConnectionState.disconnected,
  );
}

typedef DeviceRejectionEvent = ({String deviceId, RejectionMessage rejection});

final latestRejectionProvider = StateProvider<DeviceRejectionEvent?>((ref) => null);

typedef DeviceNvsFaultEvent = ({String deviceId, NvsFaultAlertMessage alert});

final latestNvsFaultProvider = StateProvider<DeviceNvsFaultEvent?>((ref) => null);

typedef DuplicateSerialEvent = ({String deviceId, String serial});

final duplicateSerialProvider = StateProvider<DuplicateSerialEvent?>((ref) => null);

final printFailureProvider = StateProvider<String?>((ref) => null);

final devicesProvider =
    StateNotifierProvider<DevicesNotifier, Map<String, DeviceInfo>>((ref) {
  return DevicesNotifier(ref);
});

class DevicesNotifier extends StateNotifier<Map<String, DeviceInfo>> {
  DevicesNotifier(this._ref, {bool enableMqtt = true}) : super({}) {
    if (enableMqtt) _init();
  }

  /// Instância sem MQTT para testes de widget.
  @visibleForTesting
  DevicesNotifier.forTesting(this._ref, Map<String, DeviceInfo> devices)
      : super(devices);

  final Ref _ref;
  StreamSubscription<(String, String)>? _sub;
  Timer? _staleTimer;
  final MessagePump _messagePump = MessagePump();
  final Map<String, DateTime> _batchStartedAt = {};
  final Map<String, int> _rejectionEpoch = {};
  final Map<String, int> _batchAckEpoch = {};
  final Set<String> _autoEndBatchSent = {};
  final Map<int, String> _bancadaToDeviceId = {};

  void _init() {
    try {
      final service = _ref.read(mqttServiceProvider);
      final config = _ref.read(appConfigProvider);

      final mqttConfig = MqttConnectionConfig.fromAppConfig(config);

      unawaited(AppLog.write('MQTT: conectando ${mqttConfig.logLabel}'));
      service.connect(mqttConfig);

      _sub = service.messages.listen((event) {
        _messagePump.enqueue(() => _handleMessage(event));
      });
      _staleTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkStaleDevices());
      unawaited(AppLog.write('MQTT: listener ativo'));
    } catch (e, st) {
      unawaited(AppLog.write('MQTT: falha ao iniciar', error: e, stack: st));
    }
  }

  void reconnect() {
    final config = _ref.read(appConfigProvider);
    final service = _ref.read(mqttServiceProvider);
    service.connect(MqttConnectionConfig.fromAppConfig(config));
  }

  DeviceInfo _getOrCreate(String deviceId) {
    return state.putIfAbsent(deviceId, () => DeviceInfo(deviceId: deviceId));
  }

  int? _bancadaNumFor(String deviceId) => state[deviceId]?.bancadaNum;

  String? _deviceIdForBancada(int bancadaNum) => _bancadaToDeviceId[bancadaNum];

  Future<void> _publishForDevice(String deviceId, Map<String, dynamic> payload) async {
    final bancada = _bancadaNumFor(deviceId);
    if (bancada == null) {
      throw StateError('Bancada não identificada para $deviceId');
    }
    await _ref.read(mqttServiceProvider).publishCommand(bancada, payload);
  }

  void _linkBancada(int bancadaNum, String deviceId) {
    _bancadaToDeviceId[bancadaNum] = deviceId;
    final device = _getOrCreate(deviceId);
    device.bancadaNum = bancadaNum;
  }

  void _checkStaleDevices() {
    const timeout = AppConfig.staleDeviceTimeout;
    final now = DateTime.now();
    var changed = false;
    for (final device in state.values) {
      if (!device.isOnline || device.lastSeen == null) {
        continue;
      }
      if (isDeviceStale(device.lastSeen, now, timeout)) {
        device.isOnline = false;
        changed = true;
      }
    }
    if (changed) {
      state = {...state};
    }
  }

  void _emitRejection(String deviceId, RejectionMessage rejection) {
    final device = _getOrCreate(deviceId);
    device.lastRejection = rejection;
    _rejectionEpoch[deviceId] = (_rejectionEpoch[deviceId] ?? 0) + 1;
    _ref.read(latestRejectionProvider.notifier).state = (
      deviceId: deviceId,
      rejection: rejection,
    );
  }

  void _emitBatchConfigured(String deviceId, BatchEventMessage event) {
    if (!event.isConfigured) return;
    _batchAckEpoch[deviceId] = (_batchAckEpoch[deviceId] ?? 0) + 1;
    _setDeviceEstado(deviceId, DeviceFsmState.batchReady);
  }

  void _emitNvsFault(String deviceId, NvsFaultAlertMessage alert) {
    final device = _getOrCreate(deviceId);
    device.lastNvsFault = alert;
    _ref.read(latestNvsFaultProvider.notifier).state = (
      deviceId: deviceId,
      alert: alert,
    );
  }

  void _setDeviceEstado(String deviceId, DeviceFsmState estado) {
    final device = _getOrCreate(deviceId);
    device.estado = estado;
    state = {...state};
  }

  /// Atualiza estado exibido (ensaio local, demo, etc.).
  void updateDeviceEstado(String deviceId, DeviceFsmState estado) {
    _setDeviceEstado(deviceId, estado);
  }

  /// Aguarda rejeição MQTT após um comando (firmware não envia ACK explícito).
  Future<String?> waitForRejection(
    String deviceId, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final epochBefore = _rejectionEpoch[deviceId] ?? 0;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if ((_rejectionEpoch[deviceId] ?? 0) > epochBefore) {
        return state[deviceId]?.lastRejection?.motivo;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return null;
  }

  /// Aguarda ACK `batch/configurado` ou estado `BATCH_READY` após SET_BATCH.
  Future<bool> waitForBatchConfigured(
    String deviceId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final epochBefore = _batchAckEpoch[deviceId] ?? 0;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if ((_batchAckEpoch[deviceId] ?? 0) > epochBefore) return true;
      final estado = state[deviceId]?.estado;
      if (estado == DeviceFsmState.batchReady) return true;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return state[deviceId]?.estado == DeviceFsmState.batchReady;
  }

  Future<void> _handleMessage((String, String) event) async {
    final (topic, payload) = event;
    final site = _ref.read(appConfigProvider).mqttSite;
    final bancadaNum = MqttTopics.extractBancadaNum(topic, site: site);
    if (bancadaNum == null) return;

    String? deviceId;
    if (topic.endsWith('/heartbeat')) {
      final hb = MqttParser.parseHeartbeat(payload);
      if (hb == null) return;
      if (hb.site != null && hb.site!.isNotEmpty && hb.site != site) return;
      deviceId = hb.deviceId;
      if (deviceId == null || deviceId.isEmpty) return;
      _linkBancada(hb.bancada ?? bancadaNum, deviceId);
    } else {
      deviceId = _deviceIdForBancada(bancadaNum);
      if (deviceId == null) {
        deviceId = await _ref.read(databaseProvider).getDeviceIdByBancadaNumero(bancadaNum);
        if (deviceId != null) {
          _linkBancada(bancadaNum, deviceId);
        }
      }
      if (deviceId == null) return;
    }

    final device = _getOrCreate(deviceId);
    device.bancadaNum ??= bancadaNum;
    final now = DateTime.now();

    if (topic.endsWith('/presenca')) {
      final online = payload.trim() == 'online';
      device.isOnline = online;
      device.lastSeen = now;
      if (online) {
        await _ref.read(databaseProvider).syncBancadaFromFirmware(deviceId, bancadaNum);
      }
      if (!online) {
        await _ref.read(firestoreSyncServiceProvider).enqueueDeviceUpdate(
          deviceId: deviceId,
          estado: device.estado,
          firmwareVersion: device.firmwareVersion,
          rssi: device.rssi,
          filaOffline: device.fila,
          online: false,
          force: true,
        );
      }
    } else if (topic.endsWith('/heartbeat')) {
      final hb = MqttParser.parseHeartbeat(payload);
      if (hb != null) {
        device.estado = hb.estado;
        device.rssi = hb.rssi;
        device.uptime = hb.uptime;
        device.fila = hb.fila;
        device.firmwareVersion = hb.firmwareVersion;
        device.isOnline = true;
        device.lastSeen = now;
        await _ref.read(databaseProvider).syncBancadaFromFirmware(
          deviceId,
          hb.bancada ?? bancadaNum,
        );
        if (hb.estado != DeviceFsmState.hardwareFault) {
          device.lastHardwareAlert = null;
        }
        await _ref.read(firestoreSyncServiceProvider).enqueueDeviceUpdate(
          deviceId: deviceId,
          estado: hb.estado,
          firmwareVersion: hb.firmwareVersion,
          rssi: hb.rssi,
          filaOffline: hb.fila,
          online: true,
        );
      }
    } else if (topic.endsWith('/alerta')) {
      final nvsFault = MqttParser.parseNvsFaultAlert(payload);
      if (nvsFault != null) {
        _emitNvsFault(deviceId, nvsFault);
        device.lastSeen = now;
      }
      final alert = MqttParser.parseHardwareAlert(payload);
      if (alert != null) {
        if (alert.isRecovery) {
          device.lastHardwareAlert = null;
        } else if (alert.falha != null) {
          device.lastHardwareAlert = alert.falha;
          await _ref.read(databaseProvider).insertHardwareEvent(
                deviceId: deviceId,
                falha: alert.falha!,
              );
          _ref.read(localDataRevisionProvider.notifier).state++;
        }
        device.lastSeen = now;
      }
    } else if (topic.endsWith('/calibracao')) {
      final service = _ref.read(mqttServiceProvider);
      final sample = MqttParser.parseCalibrationSample(payload);
      if (sample != null) {
        service.emitCalibrationSample(deviceId, sample);
        device.lastSeen = now;
      }
      final cal = MqttParser.parseCalibration(payload);
      if (cal != null) {
        device.lastCalibration = cal.potenciaMedia;
        device.lastSeen = now;
        service.emitCalibrationComplete(deviceId, cal);
      }
    } else if (topic.endsWith('/ensaio')) {
      final ensaio = MqttParser.parseEnsaioPayload(payload);
      if (ensaio != null) {
        _ref.read(ensaioRemoteStatusProvider.notifier).state = (
          deviceId: deviceId,
          msg: ensaio,
        );
        if (ensaio.isCompleted || ensaio.isFailed) {
          _setDeviceEstado(deviceId, DeviceFsmState.idle);
        } else if (ensaio.isStarted || ensaio.isCycle) {
          _setDeviceEstado(deviceId, DeviceFsmState.testing);
        }
        device.lastSeen = now;
      }
    } else if (topic.endsWith('/status')) {
      final parsed = parseMqttStatusPayload(payload);
      if (parsed.tests.isEmpty &&
          parsed.rejections.isEmpty &&
          payload.trim().isNotEmpty &&
          payload.contains('"tipo"')) {
        final preview = payload.trim();
        final clipped = preview.length > 200 ? '${preview.substring(0, 200)}…' : preview;
        unawaited(AppLog.write('MQTT status: payload não parseado ($topic): $clipped'));
      }
      for (final rejection in parsed.rejections) {
        _emitRejection(deviceId, rejection);
        device.lastSeen = now;
      }
      for (final batchEvent in parsed.batchEvents) {
        if (batchEvent.isConfigured) {
          _emitBatchConfigured(deviceId, batchEvent);
        } else if (batchEvent.isEnded) {
          clearActiveBatch(deviceId);
          _setDeviceEstado(deviceId, DeviceFsmState.idle);
        }
        device.lastSeen = now;
      }
      for (final test in parsed.tests) {
        await processTestResult(deviceId, test);
        device.lastSeen = now;
      }
    }

    state = {...state};
  }

  /// Processa resultado de teste (MQTT ou simulador de desenvolvimento).
  Future<void> processTestResult(
    String deviceId,
    TestResultMessage test, {
    String? operador,
    bool? isRetest,
  }) async {
    final device = _getOrCreate(deviceId);
    device.lastTestResult = test;

    final db = _ref.read(databaseProvider);
    if (await db.testExistsForOpSequencial(test.numeroOp, test.sequencial)) {
      if (!test.isApproved) {
        unawaited(AppLog.write(
          'MQTT: rejeição duplicada ignorada OP=${test.numeroOp} seq=${test.sequencial}',
        ));
        return;
      }
      if (await db.hasApprovedTestForOpSequencial(test.numeroOp, test.sequencial)) {
        unawaited(AppLog.write(
          'MQTT: teste duplicado ignorado OP=${test.numeroOp} seq=${test.sequencial}',
        ));
        return;
      }
      // Aprovação após reprovação no mesmo sequencial (firmware reutiliza o número).
    }

    final operadorFinal =
        operador ?? await resolveOperadorLabel(_ref);
    final operatorId = await resolveOperatorId(_ref);
    final operatorCodigo = await resolveOperatorCodigo(_ref);
    final batch = device.activeBatch;
    final bool retest = isRetest ?? _ref.read(retestModeProvider);
    String? serial;
    if (test.isApproved && !retest) {
      final candidate = generateFullSerial(
        idProduto: test.idProduto,
        ano: test.ano,
        sequencial: test.sequencial,
      );
      final duplicate = await db.serialExists(candidate);
      if (duplicate) {
        _ref.read(duplicateSerialProvider.notifier).state = (
          deviceId: deviceId,
          serial: candidate,
        );
      } else {
        serial = candidate;
        final config = _ref.read(appConfigProvider);
        if (config.markingMode == MarkingMode.laser) {
          await db.addToMarkQueue(serial: serial, numeroOp: test.numeroOp);
          await _maybeStartMarkServer();
        } else {
          await db.addLabelToBuffer(serial: serial, numeroOp: test.numeroOp);
          await _maybePrintLabels(db);
        }
        await db.bumpSerialCounter(
          idProduto: test.idProduto,
          ano: test.ano,
          sequencial: test.sequencial,
        );
        _advanceBatchSequencial(deviceId, test);
      }
    }

    await db.insertTestResult(
      deviceId: deviceId,
      numeroOp: test.numeroOp,
      veredito: test.veredito,
      potenciaMedia: test.potenciaMedia,
      sequencial: test.sequencial,
      aprovadosNoLote: test.aprovadosNoLote,
      serial: serial,
      operador: operadorFinal,
      tempoTesteSec: batch?.tempoTeste,
      potenciaMin: batch?.potenciaMin,
      potenciaMax: batch?.potenciaMax,
      operatorId: operatorId,
      isRetest: retest,
    );
    if (!_ref.read(demoModeProvider)) {
      await _ref.read(firestoreSyncServiceProvider).enqueueTestResult(
        deviceId: deviceId,
        test: test,
        serial: serial,
        operador: operadorFinal,
        operatorCodigo: operatorCodigo,
        tempoTesteSec: batch?.tempoTeste,
        potenciaMin: batch?.potenciaMin,
        potenciaMax: batch?.potenciaMax,
        isRetest: retest,
      );
    }
    _ref.read(localDataRevisionProvider.notifier).state++;
    state = {...state};

    if (!retest) {
      await _maybeAutoEndBatch(deviceId, test);
    }
  }

  void _advanceBatchSequencial(String deviceId, TestResultMessage test) {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null || batch.numeroOp != test.numeroOp) return;
    device!.activeBatch = batch.copyWith(proximoSequencial: test.sequencial + 1);
  }

  static const devSimulatorOperador = 'dev-simulator';

  /// Simula um ciclo de teste (desenvolvimento ou modo demonstração).
  Future<void> simulateTestResult(
    String deviceId, {
    bool? forceApproved,
    double approvalRate = 0.85,
  }) async {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null) {
      throw StateError('Configure um lote antes de simular');
    }

    final metrics = await _ref.read(databaseProvider).getBatchMetrics(batch.numeroOp);
    final retest = _ref.read(retestModeProvider);
    final rng = Random();
    final approved = forceApproved ?? (rng.nextDouble() < approvalRate);
    final potencia = approved
        ? batch.potenciaMin +
            rng.nextDouble() * (batch.potenciaMax - batch.potenciaMin)
        : (rng.nextBool()
            ? batch.potenciaMin - 1.5 - rng.nextDouble() * 3
            : batch.potenciaMax + 1.5 + rng.nextDouble() * 3);

    final aprovadosNoLote = approved && !retest
        ? metrics.aprovados + 1
        : metrics.aprovados;
    final sequencial = retest && approved
        ? batch.proximoSequencial
        : nextBatchSequencial(batch);
    final test = TestResultMessage(
      numeroOp: batch.numeroOp,
      idProduto: batch.idProduto,
      ano: batch.ano,
      veredito: approved ? 'APROVADO' : 'REPROVADO',
      potenciaMedia: potencia,
      sequencial: sequencial,
      aprovadosNoLote: aprovadosNoLote,
    );

    _setDeviceEstado(deviceId, DeviceFsmState.testing);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final useSessionOperador = _ref.read(demoModeProvider);
    await processTestResult(
      deviceId,
      test,
      operador: useSessionOperador ? null : devSimulatorOperador,
      isRetest: retest,
    );
    _setDeviceEstado(deviceId, DeviceFsmState.batchReady);
    _ref.read(batchDevSimulatorUsedProvider.notifier).state = true;
  }

  /// Garante bancada virtual online para demonstrações.
  void ensureDemoDevice(String deviceId) {
    final device = _getOrCreate(deviceId);
    device.isOnline = true;
    device.bancadaNum = kDemoBancadaNum;
    device.lastSeen = DateTime.now();
    if (device.estado == DeviceFsmState.unknown) {
      device.estado = DeviceFsmState.idle;
    }
    state = {...state};
  }

  Future<void> _maybePrintLabels(AppDatabase db) async {
    final config = _ref.read(appConfigProvider);
    if (config.markingMode == MarkingMode.laser) return;

    final entries = await db.getLabelBuffer();
    if (entries.length < 3 || entries.length % 3 != 0) return;

    final toPrint = entries.take(3).toList();
    final items = await resolveLabelZplItems(db, toPrint.map((e) => e.serial).toList());
    LabelPrinterTransport printer;
    try {
      printer = createLabelPrinterTransport(config);
    } catch (e) {
      _ref.read(printFailureProvider.notifier).state =
          formatPrinterError(e, config.printerMode);
      return;
    }

    try {
      await printer.sendZpl(generateZplLabelRow(items));
      await db.removeLabelsFromBuffer(toPrint.map((e) => e.id).toList());
      _ref.read(printFailureProvider.notifier).state = null;
    } catch (e) {
      _ref.read(printFailureProvider.notifier).state =
          formatPrinterError(e, config.printerMode);
    }
  }

  Future<void> _maybeStartMarkServer() async {
    try {
      await _ref.read(markQueueProcessorProvider).ensureRunning();
      _ref.read(markFailureProvider.notifier).state = null;
    } catch (e) {
      _ref.read(markFailureProvider.notifier).state = formatMarkingError(e);
    }
  }

  Future<void> _flushLabelsForOp(AppDatabase db, String numeroOp) async {
    final config = _ref.read(appConfigProvider);
    if (config.markingMode == MarkingMode.laser) {
      await _maybeStartMarkServer();
      return;
    }

    final entries = await db.getLabelBuffer();
    final opEntries = entries.where((e) => e.numeroOp == numeroOp).toList();
    if (opEntries.isEmpty) return;

    LabelPrinterTransport printer;
    try {
      printer = createLabelPrinterTransport(config);
    } catch (e) {
      _ref.read(printFailureProvider.notifier).state =
          formatPrinterError(e, config.printerMode);
      return;
    }

    final items = await resolveLabelZplItems(db, opEntries.map((e) => e.serial).toList());
    final printEntries = <({int id, LabelZplItem item})>[];
    for (var i = 0; i < opEntries.length; i++) {
      printEntries.add((id: opEntries[i].id, item: items[i]));
    }
    final result = await printLabelBatches(
      entries: printEntries,
      sendZpl: (batch) => printer.sendZpl(generateZplLabelRow(batch)),
    );
    if (result.printedIds.isNotEmpty) {
      await db.removeLabelsFromBuffer(result.printedIds);
    }
    if (result.error != null) {
      _ref.read(printFailureProvider.notifier).state =
          formatPrinterError(result.error!, config.printerMode);
    }
  }

  Future<void> _maybeAutoEndBatch(String deviceId, TestResultMessage test) async {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null || batch.numeroOp != test.numeroOp) return;
    if (batch.quantidadeTotal <= 0) return;
    if (test.aprovadosNoLote < batch.quantidadeTotal) return;
    if (_autoEndBatchSent.contains(deviceId)) return;

    _autoEndBatchSent.add(deviceId);
    await _flushLabelsForOp(_ref.read(databaseProvider), batch.numeroOp);
    final rejection = await sendEndBatch(deviceId);
    if (rejection == null) {
      _ref.read(autoBatchEndedProvider.notifier).state = (
        deviceId: deviceId,
        numeroOp: test.numeroOp,
      );
    } else {
      _autoEndBatchSent.remove(deviceId);
    }
  }

  void setActiveBatch(String deviceId, BatchConfig batch) {
    final device = _getOrCreate(deviceId);
    device.activeBatch = batch;
    _batchStartedAt[deviceId] = DateTime.now();
    state = {...state};
  }

  void clearActiveBatch(String deviceId) {
    final device = state[deviceId];
    if (device != null) {
      device.activeBatch = null;
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

  /// Publica END_BATCH e retorna motivo de rejeição, ou null se aceito.
  Future<String?> sendEndBatch(String deviceId) async {
    if (_ref.read(demoModeProvider)) {
      _ref.read(demoAutoPlayProvider.notifier).state = false;
      clearActiveBatch(deviceId);
      _setDeviceEstado(deviceId, DeviceFsmState.idle);
      _ref.read(retestModeProvider.notifier).state = false;
      return null;
    }

    final service = _ref.read(mqttServiceProvider);
    final device = state[deviceId];
    final batch = device?.activeBatch;
    final startedAt = _batchStartedAt[deviceId];
    if (service.currentState == AppMqttConnectionState.connected) {
      await _publishForDevice(deviceId, {'cmd': 'END_BATCH'});
      final rejection = await waitForRejection(deviceId);
      if (rejection != null) return rejection;
    }

    if (batch != null) {
      await _ref.read(databaseProvider).lockOp(batch.numeroOp);
    }
    if (batch != null && startedAt != null) {
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
    return null;
  }

  Future<void> sendStartCalibration(String deviceId) async {
    final service = _ref.read(mqttServiceProvider);
    await _publishForDevice(deviceId, {'cmd': 'START_CALIBRATION'});
  }

  Future<void> sendStartEnsaio(String deviceId, EnsaioConfig config) async {
    await _publishForDevice(deviceId, config.toMqttPayload());
    _setDeviceEstado(deviceId, DeviceFsmState.testing);
  }

  Future<void> sendStopEnsaio(String deviceId) async {
    await _publishForDevice(deviceId, {'cmd': 'STOP_ENSAIO'});
  }

  /// Apaga credenciais Wi-Fi (e opcionalmente broker MQTT) na NVS da bancada.
  /// Retorna motivo de rejeição, ou null se aceito.
  Future<String?> sendResetWifi(String deviceId, {bool clearMqtt = false}) async {
    final service = _ref.read(mqttServiceProvider);
    if (service.currentState != AppMqttConnectionState.connected) {
      return 'mqtt_desconectado';
    }
    await _publishForDevice(deviceId, {
      'cmd': 'RESET_WIFI',
      if (clearMqtt) 'clear_mqtt': true,
    });
    return waitForRejection(deviceId);
  }

  Future<void> sendOtaUpdate(String deviceId, String url) async {
    await _publishForDevice(deviceId, {'cmd': 'OTA_UPDATE', 'url': url});
  }

  /// Envia OTA_UPDATE para vários dispositivos (campanha).
  Future<void> sendOtaCampaign(List<String> deviceIds, String url) async {
    for (final deviceId in deviceIds) {
      await _publishForDevice(deviceId, {'cmd': 'OTA_UPDATE', 'url': url});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _staleTimer?.cancel();
    super.dispose();
  }
}

final selectedDeviceIdProvider = StateProvider<String?>((ref) {
  return ref.watch(appConfigProvider).selectedDeviceId;
});

final rejectionStreamProvider = StreamProvider<RejectionMessage>((ref) {
  return ref.watch(mqttServiceProvider).rejections;
});

final otaStreamProvider = StreamProvider<OtaStatusMessage>((ref) {
  return ref.watch(mqttServiceProvider).otaEvents;
});

final calibrationSamplesProvider =
    StreamProvider<({String deviceId, CalibrationSampleMessage sample})>((ref) {
  return ref.watch(mqttServiceProvider).calibrationSamples;
});

final calibrationCompleteProvider =
    StreamProvider<({String deviceId, CalibrationMessage result})>((ref) {
  return ref.watch(mqttServiceProvider).calibrationComplete;
});
