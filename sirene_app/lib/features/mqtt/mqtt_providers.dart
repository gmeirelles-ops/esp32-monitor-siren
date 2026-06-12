import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/mqtt_topics.dart';
import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/device_stale.dart';
import '../cloud/auth/auth_providers.dart';
import '../cloud/sync/sync_providers.dart';
import '../labels/label_printer.dart';
import '../labels/zpl_generator.dart';
import '../serial/itf_check_digit.dart';
import 'message_pump.dart';
import '../batch/batch_live_providers.dart';
import '../batch/batch_serial_logic.dart';
import '../dashboard/dashboard_providers.dart';
import '../operators/operators_provider.dart';
import 'models/mqtt_messages.dart';
import 'mqtt_parser.dart';
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

typedef DeviceRejectionEvent = ({String deviceId, RejectionMessage rejection});

final latestRejectionProvider = StateProvider<DeviceRejectionEvent?>((ref) => null);

typedef DuplicateSerialEvent = ({String deviceId, String serial});

final duplicateSerialProvider = StateProvider<DuplicateSerialEvent?>((ref) => null);

final printFailureProvider = StateProvider<String?>((ref) => null);

final devicesProvider =
    StateNotifierProvider<DevicesNotifier, Map<String, DeviceInfo>>((ref) {
  return DevicesNotifier(ref);
});

class DevicesNotifier extends StateNotifier<Map<String, DeviceInfo>> {
  DevicesNotifier(this._ref) : super({}) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<(String, String)>? _sub;
  Timer? _staleTimer;
  final MessagePump _messagePump = MessagePump();
  final Map<String, DateTime> _batchStartedAt = {};
  final Map<String, int> _rejectionEpoch = {};

  void _init() {
    final service = _ref.read(mqttServiceProvider);
    final config = _ref.read(appConfigProvider);

    service.connect(config.mqttHost, config.mqttPort);

    _sub = service.messages.listen((event) {
      _messagePump.enqueue(() => _handleMessage(event));
    });
    _staleTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkStaleDevices());
  }

  void reconnect() {
    final config = _ref.read(appConfigProvider);
    final service = _ref.read(mqttServiceProvider);
    service.connect(config.mqttHost, config.mqttPort);
  }

  DeviceInfo _getOrCreate(String deviceId) {
    return state.putIfAbsent(deviceId, () => DeviceInfo(deviceId: deviceId));
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

  void _setDeviceEstado(String deviceId, DeviceFsmState estado) {
    final device = _getOrCreate(deviceId);
    device.estado = estado;
    state = {...state};
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

  Future<void> _handleMessage((String, String) event) async {
    final (topic, payload) = event;
    final deviceId = MqttTopics.extractDeviceId(topic);
    if (deviceId == null) return;

    final device = _getOrCreate(deviceId);
    final now = DateTime.now();

    if (topic.endsWith('/presenca')) {
      final online = payload.trim() == 'online';
      device.isOnline = online;
      device.lastSeen = now;
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
      final cal = MqttParser.parseCalibration(payload);
      if (cal != null) {
        device.lastCalibration = cal.potenciaMedia;
        device.lastSeen = now;
      }
    } else if (topic.endsWith('/status')) {
      final json = MqttParser.tryParseJson(payload);
      if (json != null) {
        final rejection = MqttParser.parseRejection(json);
        if (rejection != null) {
          _emitRejection(deviceId, rejection);
          device.lastSeen = now;
        }

        final test = MqttParser.parseTestResult(json);
        if (test != null) {
          await processTestResult(deviceId, test);
          device.lastSeen = now;
        }
      }
    }

    state = {...state};
  }

  /// Processa resultado de teste (MQTT ou simulador de desenvolvimento).
  Future<void> processTestResult(
    String deviceId,
    TestResultMessage test, {
    String? operador,
  }) async {
    final device = _getOrCreate(deviceId);
    device.lastTestResult = test;

    final db = _ref.read(databaseProvider);
    final operadorFinal =
        operador ?? await resolveOperadorLabel(_ref);
    String? serial;
    if (test.isApproved) {
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
        await db.addLabelToBuffer(serial: serial, numeroOp: test.numeroOp);
        await db.bumpSerialCounter(
          idProduto: test.idProduto,
          ano: test.ano,
          sequencial: test.sequencial,
        );
        await _maybePrintLabels(db);
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
    );
    await _ref.read(firestoreSyncServiceProvider).enqueueTestResult(
      deviceId: deviceId,
      test: test,
      serial: serial,
      operador: operadorFinal,
    );
    _ref.read(localDataRevisionProvider.notifier).state++;
    state = {...state};
  }

  void _advanceBatchSequencial(String deviceId, TestResultMessage test) {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null || batch.numeroOp != test.numeroOp) return;
    device!.activeBatch = batch.copyWith(proximoSequencial: test.sequencial + 1);
  }

  static const devSimulatorOperador = 'dev-simulator';

  /// Simula um ciclo de teste com potência fictícia (somente desenvolvimento).
  Future<void> simulateTestResult(
    String deviceId, {
    bool? forceApproved,
  }) async {
    final device = state[deviceId];
    final batch = device?.activeBatch;
    if (batch == null) {
      throw StateError('Configure um lote antes de simular');
    }

    final metrics = await _ref.read(databaseProvider).getBatchMetrics(batch.numeroOp);
    final rng = Random();
    final approved = forceApproved ?? rng.nextBool();
    final potencia = approved
        ? batch.potenciaMin +
            rng.nextDouble() * (batch.potenciaMax - batch.potenciaMin)
        : (rng.nextBool()
            ? batch.potenciaMin - 1.5 - rng.nextDouble() * 3
            : batch.potenciaMax + 1.5 + rng.nextDouble() * 3);

    final aprovadosNoLote = approved ? metrics.aprovados + 1 : metrics.aprovados;
    final sequencial = nextBatchSequencial(batch);
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
    await processTestResult(deviceId, test, operador: devSimulatorOperador);
    _setDeviceEstado(deviceId, DeviceFsmState.batchReady);
    _ref.read(batchDevSimulatorUsedProvider.notifier).state = true;
  }

  Future<void> _maybePrintLabels(AppDatabase db) async {
    final entries = await db.getLabelBuffer();
    if (entries.length < 3 || entries.length % 3 != 0) return;

    final toPrint = entries.take(3).toList();
    final serials = toPrint.map((e) => e.serial).toList();
    final config = _ref.read(appConfigProvider);
    final printer = LabelPrinter(host: config.printerHost, port: config.printerPort);

    try {
      await printer.sendZpl(generateZplLabelRow(serials));
      await db.removeLabelsFromBuffer(toPrint.map((e) => e.id).toList());
      _ref.read(printFailureProvider.notifier).state = null;
    } catch (e) {
      _ref.read(printFailureProvider.notifier).state = 'Erro na impressão automática: $e';
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
    final service = _ref.read(mqttServiceProvider);
    await service.publishCommand(deviceId, batch.toSetBatchJson());
    final rejection = await waitForRejection(deviceId);
    if (rejection != null) return rejection;

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
    final service = _ref.read(mqttServiceProvider);
    final device = state[deviceId];
    final batch = device?.activeBatch;
    final startedAt = _batchStartedAt[deviceId];
    await service.publishCommand(deviceId, {'cmd': 'END_BATCH'});
    final rejection = await waitForRejection(deviceId);
    if (rejection != null) return rejection;

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
    clearActiveBatch(deviceId);
    _setDeviceEstado(deviceId, DeviceFsmState.idle);
    return null;
  }

  Future<void> sendStartCalibration(String deviceId) async {
    final service = _ref.read(mqttServiceProvider);
    await service.publishCommand(deviceId, {'cmd': 'START_CALIBRATION'});
  }

  Future<void> sendOtaUpdate(String deviceId, String url) async {
    final service = _ref.read(mqttServiceProvider);
    await service.publishCommand(deviceId, {'cmd': 'OTA_UPDATE', 'url': url});
  }

  /// Envia OTA_UPDATE para vários dispositivos (campanha).
  Future<void> sendOtaCampaign(List<String> deviceIds, String url) async {
    final service = _ref.read(mqttServiceProvider);
    for (final deviceId in deviceIds) {
      await service.publishCommand(deviceId, {'cmd': 'OTA_UPDATE', 'url': url});
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
