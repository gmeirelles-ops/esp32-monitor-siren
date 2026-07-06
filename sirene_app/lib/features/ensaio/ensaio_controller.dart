import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../demo/demo_constants.dart';
import '../demo/demo_providers.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../operators/operators_provider.dart';
import '../../shared/reports/report_file_save.dart';
import 'ensaio_pdf_export.dart';
import 'ensaio_providers.dart';

/// Controla ensaio local (demo) ou remoto (MQTT).
final ensaioControllerProvider = Provider<EnsaioController>((ref) {
  final controller = EnsaioController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class EnsaioController {
  EnsaioController(this._ref);

  final Ref _ref;
  Timer? _localTimer;
  Timer? _uiTick;
  int _localElapsed = 0;
  int _localCycle = 0;
  EnsaioConfig? _activeConfig;
  String? _activeDeviceId;
  String? _activeNome;

  void dispose() {
    _localTimer?.cancel();
    _uiTick?.cancel();
  }

  void applyRemoteStatus(String deviceId, EnsaioStatusMessage msg, EnsaioConfig config) {
    var session = _ref.read(ensaioSessionProvider);
    if (session != null && session.deviceId != deviceId) return;

    if (msg.isStarted) {
      final activeConfig = EnsaioConfig(
        onSeconds: msg.onSec ?? config.onSeconds,
        offSeconds: msg.offSec ?? config.offSeconds,
        totalSeconds: msg.duracaoTotalSec ?? config.totalSeconds,
      );
      _ref.read(ensaioConfigProvider.notifier).state = activeConfig;
      if (session == null) return;
      _ref.read(ensaioSessionProvider.notifier).state = session.copyWith(
        config: activeConfig,
        phase: EnsaioPhase.on,
        remainingSeconds: activeConfig.totalSeconds,
      );
      _startUiTick();
      return;
    }

    if (msg.isCycle) {
      session ??= _ref.read(ensaioSessionProvider);
      if (session == null) return;

      final phase = msg.isOnPhase
          ? EnsaioPhase.on
          : msg.isOffPhase
              ? EnsaioPhase.off
              : session.phase;
      final remaining = (session.config.totalSeconds - msg.elapsedSec)
          .clamp(0, session.config.totalSeconds);

      _ref.read(ensaioSessionProvider.notifier).state = session.copyWith(
        phase: phase,
        cycle: msg.n ?? session.cycle,
        remainingSeconds: remaining,
        phaseEndsAt: DateTime.now().add(
          Duration(seconds: _phaseSeconds(session.config, phase)),
        ),
      );
      return;
    }

    if (session == null) return;

    if (msg.isCompleted) {
      final phase = msg.isStopped ? EnsaioPhase.interrupted : EnsaioPhase.completed;
      final updated = session.copyWith(
        phase: phase,
        cycle: msg.ciclos,
        remainingSeconds: 0,
      );
      _ref.read(ensaioSessionProvider.notifier).state = updated;
      _stopUiTick();
      unawaited(
        _finalizeSession(
          updated,
          ciclos: msg.ciclos,
          elapsedSec: msg.elapsedSec,
          motivo: msg.motivo ?? (msg.isStopped ? 'parado' : 'duracao'),
        ),
      );
      return;
    }

    if (msg.isFailed) {
      final updated = session.copyWith(
        phase: EnsaioPhase.interrupted,
        remainingSeconds: 0,
      );
      _ref.read(ensaioSessionProvider.notifier).state = updated;
      _stopUiTick();
      unawaited(
        _finalizeSession(
          updated,
          ciclos: session.cycle,
          elapsedSec: session.elapsedSeconds,
          motivo: msg.motivo ?? 'falha',
          status: 'falha',
        ),
      );
    }
  }

  int _phaseSeconds(EnsaioConfig config, EnsaioPhase phase) {
    return phase == EnsaioPhase.on ? config.onSeconds : config.offSeconds;
  }

  void _startUiTick() {
    _uiTick?.cancel();
    _uiTick = Timer.periodic(const Duration(seconds: 1), (_) => _tickUi());
  }

  void _stopUiTick() {
    _uiTick?.cancel();
    _uiTick = null;
  }

  void _tickUi() {
    final session = _ref.read(ensaioSessionProvider);
    if (session == null || !session.isActive) return;

    final remaining = (session.remainingSeconds - 1).clamp(0, session.config.totalSeconds);
    _ref.read(ensaioSessionProvider.notifier).state = session.copyWith(
      remainingSeconds: remaining,
    );
    if (remaining <= 0) {
      _stopUiTick();
    }
  }

  Future<String?> start(String deviceId, String nome, EnsaioConfig config) async {
    final trimmedName = nome.trim();
    if (trimmedName.isEmpty) return 'nome_obrigatorio';

    final error = config.validate();
    if (error != null) return error;

    final demoMode = _ref.read(demoModeProvider);
    if (demoMode || deviceId == kDemoDeviceId) {
      _ref.read(devicesProvider.notifier).ensureDemoDevice(kDemoDeviceId);
      await _startLocal(deviceId, trimmedName, config, demoMode: true);
      return null;
    }

    final mqtt = _ref.read(mqttServiceProvider);
    if (mqtt.currentState != AppMqttConnectionState.connected) {
      return 'mqtt_desconectado';
    }

    final startedAt = DateTime.now();
    _ref.read(ensaioConfigProvider.notifier).state = config;
    _ref.read(ensaioSessionProvider.notifier).state = EnsaioSession(
      nome: trimmedName,
      deviceId: deviceId,
      config: config,
      startedAt: startedAt,
      phase: EnsaioPhase.on,
      cycle: 0,
      remainingSeconds: config.totalSeconds,
    );
    _startUiTick();

    final notifier = _ref.read(devicesProvider.notifier);
    await notifier.sendStartEnsaio(deviceId, config);
    final rejection = await notifier.waitForRejection(deviceId);
    if (rejection != null) {
      _ref.read(ensaioSessionProvider.notifier).state = null;
      _stopUiTick();
      return rejection;
    }

    final recordId = await _createRecord(
      nome: trimmedName,
      deviceId: deviceId,
      config: config,
      startedAt: startedAt,
      demoMode: false,
    );
    final session = _ref.read(ensaioSessionProvider);
    if (session != null) {
      _ref.read(ensaioSessionProvider.notifier).state = session.copyWith(recordId: recordId);
    }
    return null;
  }

  Future<String?> stop(String deviceId) async {
    final session = _ref.read(ensaioSessionProvider);
    if (session == null) return null;

    final demoMode = _ref.read(demoModeProvider);
    if (demoMode || deviceId == kDemoDeviceId) {
      await _stopLocal(interrupted: true);
      return null;
    }

    final mqtt = _ref.read(mqttServiceProvider);
    if (mqtt.currentState != AppMqttConnectionState.connected) {
      return 'mqtt_desconectado';
    }

    await _ref.read(devicesProvider.notifier).sendStopEnsaio(deviceId);
    final rejection = await _ref.read(devicesProvider.notifier).waitForRejection(deviceId);
    if (rejection != null && rejection != 'ensaio_inativo') {
      return rejection;
    }
    _stopUiTick();
    final updated = session.copyWith(
      phase: EnsaioPhase.interrupted,
      remainingSeconds: 0,
    );
    _ref.read(ensaioSessionProvider.notifier).state = updated;
    await _finalizeSession(
      updated,
      ciclos: updated.cycle,
      elapsedSec: updated.elapsedSeconds,
      motivo: 'parado',
    );
    return null;
  }

  Future<int> _createRecord({
    required String nome,
    required String deviceId,
    required EnsaioConfig config,
    required DateTime startedAt,
    required bool demoMode,
  }) async {
    final db = _ref.read(databaseProvider);
    final appConfig = _ref.read(appConfigProvider);
    final operator = await _ref.read(activeOperatorProvider.future);
    return db.insertEnsaioRecord(
      nome: nome,
      deviceId: deviceId,
      onSeconds: config.onSeconds,
      offSeconds: config.offSeconds,
      totalSeconds: config.totalSeconds,
      startedAt: startedAt,
      operador: operator?.nome,
      operatorId: operator?.id,
      stationId: appConfig.stationId.isEmpty ? null : appConfig.stationId,
      demoMode: demoMode,
    );
  }

  Future<void> _finalizeSession(
    EnsaioSession session, {
    required int ciclos,
    required int elapsedSec,
    String? motivo,
    String? status,
  }) async {
    if (session.finalized || session.recordId == null) return;

    final endedAt = DateTime.now();
    final finalStatus = status ??
        switch (session.phase) {
          EnsaioPhase.completed => 'concluido',
          EnsaioPhase.interrupted => 'interrompido',
          _ => 'concluido',
        };

    _ref.read(ensaioSessionProvider.notifier).state = session.copyWith(finalized: true);

    final db = _ref.read(databaseProvider);
    final existing = await db.getEnsaioRecord(session.recordId!);
    if (existing == null) return;

    final bancadas = await db.getBancadaNumeros();
    final appConfig = _ref.read(appConfigProvider);
    final pdfRecord = EnsaioRecord(
      id: existing.id,
      nome: existing.nome,
      deviceId: existing.deviceId,
      operador: existing.operador,
      operatorId: existing.operatorId,
      stationId: existing.stationId,
      onSeconds: existing.onSeconds,
      offSeconds: existing.offSeconds,
      totalSeconds: existing.totalSeconds,
      startedAt: existing.startedAt,
      endedAt: endedAt,
      status: finalStatus,
      ciclos: ciclos,
      elapsedSec: elapsedSec,
      motivo: motivo,
      pdfPath: null,
      demoMode: existing.demoMode,
    );

    final bytes = await buildEnsaioPdf(
      EnsaioPdfContext(
        record: pdfRecord,
        bancadaLabel: ensaioBancadaLabel(pdfRecord, bancadas),
        stationId: appConfig.stationId.isEmpty ? null : appConfig.stationId,
      ),
    );
    final basename = 'ensaio_${sanitizeEnsaioBasename(session.nome)}';
    final path = await saveReportBytes(basename, bytes, 'pdf');

    await db.finalizeEnsaioRecord(
      id: session.recordId!,
      status: finalStatus,
      endedAt: endedAt,
      ciclos: ciclos,
      elapsedSec: elapsedSec,
      motivo: motivo,
      pdfPath: path,
    );

    _ref.read(ensaioPdfSavedProvider.notifier).state = path;
  }

  Future<void> _startLocal(
    String deviceId,
    String nome,
    EnsaioConfig config, {
    required bool demoMode,
  }) async {
    await _stopLocal(interrupted: false, skipFinalize: true);
    _activeConfig = config;
    _activeDeviceId = deviceId;
    _activeNome = nome;
    _localElapsed = 0;
    _localCycle = 0;

    final startedAt = DateTime.now();
    final recordId = await _createRecord(
      nome: nome,
      deviceId: deviceId,
      config: config,
      startedAt: startedAt,
      demoMode: demoMode,
    );

    _ref.read(ensaioSessionProvider.notifier).state = EnsaioSession(
      recordId: recordId,
      nome: nome,
      deviceId: deviceId,
      config: config,
      startedAt: startedAt,
      phase: EnsaioPhase.on,
      cycle: 1,
      remainingSeconds: config.totalSeconds,
      phaseEndsAt: DateTime.now().add(Duration(seconds: config.onSeconds)),
    );
    _ref.read(devicesProvider.notifier).updateDeviceEstado(
          deviceId,
          DeviceFsmState.testing,
        );
    _startUiTick();

    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) => _localStep());
  }

  Future<void> _localStep() async {
    final config = _activeConfig;
    final deviceId = _activeDeviceId;
    if (config == null || deviceId == null) return;

    _localElapsed++;
    final remaining = (config.totalSeconds - _localElapsed).clamp(0, config.totalSeconds);
    final session = _ref.read(ensaioSessionProvider);
    if (session == null) return;

    if (_localElapsed >= config.totalSeconds) {
      final updated = session.copyWith(
        phase: EnsaioPhase.completed,
        remainingSeconds: 0,
        cycle: _localCycle,
      );
      _ref.read(ensaioSessionProvider.notifier).state = updated;
      await _stopLocal(interrupted: false);
      return;
    }

    var phaseElapsed = _localElapsed;
    while (phaseElapsed > config.onSeconds + config.offSeconds) {
      phaseElapsed -= config.onSeconds + config.offSeconds;
    }

    if (phaseElapsed <= config.onSeconds) {
      _localCycle = (_localElapsed ~/ (config.onSeconds + config.offSeconds)) + 1;
      final phaseRemaining = config.onSeconds - phaseElapsed + 1;
      _ref.read(ensaioSessionProvider.notifier).state = session.copyWith(
        phase: EnsaioPhase.on,
        cycle: _localCycle,
        remainingSeconds: remaining,
        phaseEndsAt: DateTime.now().add(Duration(seconds: phaseRemaining)),
      );
    } else {
      final offElapsed = phaseElapsed - config.onSeconds;
      final phaseRemaining = config.offSeconds - offElapsed + 1;
      _ref.read(ensaioSessionProvider.notifier).state = session.copyWith(
        phase: EnsaioPhase.off,
        cycle: _localCycle,
        remainingSeconds: remaining,
        phaseEndsAt: DateTime.now().add(Duration(seconds: phaseRemaining)),
      );
    }
  }

  Future<void> _stopLocal({required bool interrupted, bool skipFinalize = false}) async {
    _localTimer?.cancel();
    _localTimer = null;
    _stopUiTick();

    final deviceId = _activeDeviceId;
    if (deviceId != null) {
      _ref.read(devicesProvider.notifier).updateDeviceEstado(
            deviceId,
            DeviceFsmState.idle,
          );
    }

    var session = _ref.read(ensaioSessionProvider);
    if (session != null && interrupted) {
      session = session.copyWith(
        phase: EnsaioPhase.interrupted,
        remainingSeconds: 0,
      );
      _ref.read(ensaioSessionProvider.notifier).state = session;
    }

    if (!skipFinalize && session != null && !session.isActive) {
      await _finalizeSession(
        session,
        ciclos: session.cycle,
        elapsedSec: _localElapsed > 0 ? _localElapsed : session.elapsedSeconds,
        motivo: interrupted ? 'parado' : 'duracao',
      );
    }

    _activeConfig = null;
    _activeDeviceId = null;
    _activeNome = null;
  }
}

String formatEnsaioDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) {
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }
  if (m > 0) {
    return '${m}min ${s.toString().padLeft(2, '0')}s';
  }
  return '${s}s';
}
