part of 'mqtt_providers.dart';

mixin _DevicesNotifierInbound on _DevicesNotifierBase {
  @override
  void _cancelVerdictWatchdog(String deviceId) {
    _verdictWatchdogTimers.remove(deviceId)?.cancel();
  }

  void _scheduleVerdictWatchdog(String deviceId) {
    _cancelVerdictWatchdog(deviceId);
    _verdictWatchdogTimers[deviceId] = Timer(_DevicesNotifierBase._verdictWatchdogDuration, () {
      unawaited(_onVerdictWatchdog(deviceId));
    });
  }

  Future<void> _onVerdictWatchdog(String deviceId) async {
    final device = state[deviceId];
    if (device == null) return;
    if (device.estado != DeviceFsmState.testing && !device.awaitingMqttResult) {
      return;
    }
    final hb = device.lastHeartbeat;
    if (hb != null) {
      await _tryProcessHeartbeatLastTest(deviceId, hb);
      await _reconcileFromHeartbeat(deviceId, hb);
    }
    final after = state[deviceId];
    if (after != null &&
        (after.estado == DeviceFsmState.testing || after.awaitingMqttResult)) {
      after.awaitingMqttResult = false;
      state = {...state};
      unawaited(AppLog.write('MQTT: watchdog 15s — saiu de Testando/Aguardando ($deviceId)'));
    }
  }

  /// Reconcilia contadores, sequencial e seriais pendentes com o firmware (006).
  Future<void> _reconcileFromHeartbeat(String deviceId, HeartbeatMessage hb) async {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (device == null || batch == null) return;

    final hbOp = hb.numeroOp;
    if (hbOp == null || hbOp.isEmpty || hbOp != batch.numeroOp) return;

    if (hb.proximoSequencial != null && hb.proximoSequencial! > 0) {
      device.firmwareProximoSequencial = hb.proximoSequencial;
      if (device.activeBatch!.proximoSequencial != hb.proximoSequencial) {
        device.activeBatch = batch.copyWith(proximoSequencial: hb.proximoSequencial);
      }
    }

    final db = _ref.read(databaseProvider);
    final since = device.batchStartedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final sessionTests = await db.getTestsByOpSince(batch.numeroOp, since);
    final sessionMetrics = computeSessionBatchMetrics(sessionTests);

    final hbAprovados = hb.aprovados ?? 0;
    if (hb.ultimoVeredito != null &&
        hb.ultimoVeredito!.isNotEmpty &&
        (hbAprovados > sessionMetrics.aprovados ||
            (hb.ultimoVeredito == 'REPROVADO' && device.awaitingMqttResult))) {
      await _tryProcessHeartbeatLastTest(deviceId, hb);
    }

    if (hbAprovados > sessionMetrics.aprovados) {
      await _syncMarkingForOp(db, batch.numeroOp, since: device.batchStartedAt);
    }

    device.awaitingMqttResult = false;
    state = {...state};
  }

  void _emitRejection(String deviceId, RejectionMessage rejection) {
    final device = _getOrCreate(deviceId);
    device.lastRejection = rejection;
    _rejectionEpoch[deviceId] = (_rejectionEpoch[deviceId] ?? 0) + 1;
    if (isTransientRejection(rejection.motivo)) {
      _scheduleTransientRejectionClear(deviceId, rejection.motivo);
    }
  }

  void _scheduleTransientRejectionClear(String deviceId, String motivo) {
    _cooldownRejectionTimers[deviceId]?.cancel();
    final delay = motivo == 'peca_ja_aprovada'
        ? postApprovalCooldownDuration
        : const Duration(seconds: 4);
    _cooldownRejectionTimers[deviceId] = Timer(delay, () {
      _clearTransientRejection(deviceId);
    });
  }

  void _clearTransientRejection(String deviceId) {
    _cooldownRejectionTimers[deviceId]?.cancel();
    _cooldownRejectionTimers.remove(deviceId);
    final device = state[deviceId];
    final motivo = device?.lastRejection?.motivo;
    if (isTransientRejection(motivo)) {
      device!.lastRejection = null;
      state = {...state};
    }
  }

  @override
  void _clearRejectionAfterTest(String deviceId) {
    final device = state[deviceId];
    if (device?.lastRejection == null) return;
    device!.lastRejection = null;
    state = {...state};
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

  @override
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
  @override
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
  @override
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
        final hb = device.lastHeartbeat;
        if (hb != null && device.activeBatch != null) {
          await _reconcileFromHeartbeat(deviceId, hb);
        }
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
        device.lastHeartbeat = hb;
        final prevEstado = device.estado;
        device.estado = hb.estado;
        if (hb.proximoSequencial != null && hb.proximoSequencial! > 0) {
          device.firmwareProximoSequencial = hb.proximoSequencial;
        }
        final batch = device.activeBatch;
        if (hb.numeroOp != null &&
            hb.numeroOp!.isNotEmpty &&
            batch != null &&
            hb.numeroOp == batch.numeroOp &&
            hb.aprovados != null) {
          device.firmwareAprovados = hb.aprovados;
          device.firmwareAprovadosOp = hb.numeroOp;
        } else if (batch != null &&
            hb.numeroOp != null &&
            hb.numeroOp!.isNotEmpty &&
            hb.numeroOp != batch.numeroOp) {
          device.firmwareAprovados = null;
          device.firmwareAprovadosOp = null;
        }
        if (prevEstado == DeviceFsmState.testing &&
            hb.estado != DeviceFsmState.testing) {
          final processed = await _tryProcessHeartbeatLastTest(deviceId, hb);
          if (!processed) {
            device.awaitingMqttResult = true;
            _scheduleVerdictWatchdog(deviceId);
          } else {
            _cancelVerdictWatchdog(deviceId);
          }
        } else if (hb.ultimoVeredito != null &&
            hb.estado == DeviceFsmState.batchReady &&
            device.awaitingMqttResult) {
          await _tryProcessHeartbeatLastTest(deviceId, hb);
          _cancelVerdictWatchdog(deviceId);
        }
        if (prevEstado != DeviceFsmState.testing && hb.estado == DeviceFsmState.testing) {
          _clearTransientRejection(deviceId);
          _scheduleVerdictWatchdog(deviceId);
        }
        await _reconcileFromHeartbeat(deviceId, hb);
        final batchAfterHb = device.activeBatch;
        if (batchAfterHb != null &&
            hb.numeroOp != null &&
            hb.numeroOp!.isNotEmpty &&
            hb.numeroOp == batchAfterHb.numeroOp &&
            hb.aprovados != null &&
            batchAfterHb.quantidadeTotal > 0 &&
            hb.aprovados! >= batchAfterHb.quantidadeTotal) {
          await _maybeAutoEndBatch(deviceId, test: device.lastTestResult);
        }
        device.rssi = hb.rssi;
        device.uptime = hb.uptime;
        device.fila = hb.fila;
        device.firmwareVersion = hb.firmwareVersion;
        device.firmwareProtocolVersion = hb.protocolVersion;
        if (hb.batchNvsFault) {
          _emitNvsFault(
            deviceId,
            NvsFaultAlertMessage(
              evento: 'batch_nvs_fault',
              detalhe: 'Falha ao gravar lote na memória do dispositivo (heartbeat)',
            ),
          );
        }
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
          await _finalizeBatchLocally(deviceId);
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

  /// Fallback 005: veredito no heartbeat quando `tipo:teste` MQTT está colado/corrompido.
  Future<bool> _tryProcessHeartbeatLastTest(
    String deviceId,
    HeartbeatMessage hb,
  ) async {
    final veredito = hb.ultimoVeredito;
    if (veredito != 'APROVADO' && veredito != 'REPROVADO') {
      return false;
    }
    final sequencial = hb.ultimoSequencial;
    final potencia = hb.ultimaPotencia;
    if (sequencial == null || sequencial <= 0 || potencia == null) {
      return false;
    }

    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null) {
      return false;
    }

    final numeroOp = (hb.numeroOp != null && hb.numeroOp!.isNotEmpty)
        ? hb.numeroOp!
        : batch.numeroOp;
    if (numeroOp != batch.numeroOp) {
      return false;
    }

    final test = TestResultMessage(
      numeroOp: numeroOp,
      idProduto: batch.idProduto,
      ano: batch.ano,
      veredito: veredito!,
      potenciaMedia: potencia,
      sequencial: sequencial,
      aprovadosNoLote: hb.aprovados ?? 0,
      tsMs: hb.ultimoTsMs,
    );

    final db = _ref.read(databaseProvider);
    if (test.tsMs != null &&
        await db.testExistsByOpAndTsMs(numeroOp, test.tsMs!)) {
      device!.lastTestResult = test;
      device.awaitingMqttResult = false;
      _cancelVerdictWatchdog(deviceId);
      state = {...state};
      await _ensureMarkingForTest(db, test);
      await _maybeAutoEndBatch(deviceId, test: test);
      return true;
    }

    await processTestResult(deviceId, test);
    _cancelVerdictWatchdog(deviceId);
    return true;
  }
}
