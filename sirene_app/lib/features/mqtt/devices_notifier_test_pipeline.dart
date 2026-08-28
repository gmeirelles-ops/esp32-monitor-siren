part of 'mqtt_providers.dart';

mixin _DevicesNotifierTestPipeline on _DevicesNotifierBase {
  /// Processa resultado de teste (MQTT ou simulador de desenvolvimento).
  @override
  Future<void> processTestResult(
    String deviceId,
    TestResultMessage test, {
    String? operador,
    bool? isRetest,
  }) async {
    final device = _getOrCreate(deviceId);
    _clearRejectionAfterTest(deviceId);

    final db = _ref.read(databaseProvider);
    if (test.tsMs != null) {
      if (await db.testExistsByOpAndTsMs(test.numeroOp, test.tsMs!)) {
        unawaited(AppLog.write(
          'MQTT: teste duplicado ignorado OP=${test.numeroOp} ts_ms=${test.tsMs}',
        ));
        if (!(isRetest ?? _ref.read(retestModeProvider))) {
          await _ensureMarkingForTest(db, test);
          await _maybeAutoEndBatch(deviceId, test: test);
        }
        return;
      }
    } else if (!test.isApproved) {
      if (await db.testExistsLegacyReplay(
        test.numeroOp,
        test.sequencial,
        test.veredito,
        test.potenciaMedia,
      )) {
        unawaited(AppLog.write(
          'MQTT: rejeição legada duplicada ignorada OP=${test.numeroOp} seq=${test.sequencial}',
        ));
        if (!(isRetest ?? _ref.read(retestModeProvider))) {
          await _maybeAutoEndBatch(deviceId, test: test);
        }
        return;
      }
    } else if (await db.testExistsForOpSequencial(test.numeroOp, test.sequencial)) {
      if (await db.hasApprovedTestForOpSequencial(test.numeroOp, test.sequencial)) {
        unawaited(AppLog.write(
          'MQTT: teste duplicado ignorado OP=${test.numeroOp} seq=${test.sequencial}',
        ));
        if (!(isRetest ?? _ref.read(retestModeProvider))) {
          await _ensureMarkingForTest(db, test);
          await _maybeAutoEndBatch(deviceId, test: test);
        }
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
        unawaited(AppLog.write(
          'MQTT: serial duplicado bloqueado OP=${test.numeroOp} seq=${test.sequencial} serial=$candidate',
        ));
        return;
      }
      serial = candidate;
    }

    device.lastTestResult = test;
    device.awaitingMqttResult = false;
    _cancelVerdictWatchdog(deviceId);
    state = {...state};

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
      firmwareTsMs: test.tsMs,
    );
    _ref.read(localDataRevisionProvider.notifier).state++;
    state = {...state};

    if (test.isApproved && !retest && serial != null) {
      await db.addToMarkQueue(serial: serial, numeroOp: test.numeroOp);
      await _ensureMarkServerForOp();
      await db.bumpSerialCounter(
        idProduto: test.idProduto,
        ano: test.ano,
        sequencial: test.sequencial,
      );
      _advanceBatchSequencial(deviceId, test);
    }

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

    if (!retest) {
      await _maybeAutoEndBatch(deviceId, test: test);
    }
  }

  @override
  Future<void> _ensureMarkingForTest(AppDatabase db, TestResultMessage test) async {
    if (!test.isApproved) return;
    final row = await db.getTestByOpSequencial(test.numeroOp, test.sequencial);
    final serial = row?.serial;
    if (serial == null || serial.trim().isEmpty) return;
    await _enqueueMarking(db, serial: serial, numeroOp: test.numeroOp);
  }

  Future<void> _enqueueMarking(
    AppDatabase db, {
    required String serial,
    required String numeroOp,
  }) async {
    if (!await db.markQueueContainsSerial(serial)) {
      await db.addToMarkQueue(serial: serial, numeroOp: numeroOp);
      await _ensureMarkServerForOp();
    }
  }

  @override
  Future<void> _syncMarkingForOp(
    AppDatabase db,
    String numeroOp, {
    DateTime? since,
  }) async {
    final tests = await db.getApprovedProductionTestsForOp(numeroOp, since: since);
    for (final test in tests) {
      final serial = test.serial;
      if (serial == null || serial.trim().isEmpty) continue;
      await _enqueueMarking(db, serial: serial, numeroOp: numeroOp);
    }
  }

  @override
  Future<void> _ensureMarkServerForOp() async {
    try {
      await _ref.read(markQueueProcessorProvider).ensureRunning();
      _ref.read(markFailureProvider.notifier).state = null;
    } catch (e) {
      _ref.read(markFailureProvider.notifier).state = formatMarkingError(e);
    }
  }

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
      operador: useSessionOperador ? null : DevicesNotifier.devSimulatorOperador,
      isRetest: retest,
    );
    _setDeviceEstado(deviceId, DeviceFsmState.batchReady);
    _ref.read(batchDevSimulatorUsedProvider.notifier).state = true;
  }

  /// Garante bancada virtual online para demonstrações.
  @override
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
}
