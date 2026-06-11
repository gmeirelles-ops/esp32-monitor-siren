import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/mqtt_topics.dart';
import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/device_stale.dart';
import '../cloud/sync/sync_providers.dart';
import '../labels/label_printer.dart';
import '../labels/zpl_generator.dart';
import '../serial/itf_check_digit.dart';
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
  final Map<String, DateTime> _batchStartedAt = {};

  void _init() {
    final service = _ref.read(mqttServiceProvider);
    final config = _ref.read(appConfigProvider);

    service.connect(config.mqttHost, config.mqttPort);

    _sub = service.messages.listen(_handleMessage);
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
    _ref.read(latestRejectionProvider.notifier).state = (
      deviceId: deviceId,
      rejection: rejection,
    );
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
          device.lastTestResult = test;
          device.lastSeen = now;

          String? serial;
          if (test.isApproved) {
            serial = generateFullSerial(
              idProduto: test.idProduto,
              ano: test.ano,
              sequencial: test.sequencial,
            );
            final db = _ref.read(databaseProvider);
            await db.addLabelToBuffer(serial: serial, numeroOp: test.numeroOp);
            await _maybePrintLabels(db);
          }

          await _ref.read(databaseProvider).insertTestResult(
            deviceId: deviceId,
            numeroOp: test.numeroOp,
            veredito: test.veredito,
            potenciaMedia: test.potenciaMedia,
            sequencial: test.sequencial,
            aprovadosNoLote: test.aprovadosNoLote,
            serial: serial,
          );
          await _ref.read(firestoreSyncServiceProvider).enqueueTestResult(
            deviceId: deviceId,
            test: test,
            serial: serial,
          );
        }
      }
    }

    state = {...state};
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
    } catch (_) {
      // Impressora indisponível — seriais permanecem no buffer
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

  Future<void> sendSetBatch(String deviceId, BatchConfig batch) async {
    final service = _ref.read(mqttServiceProvider);
    await service.publishCommand(deviceId, batch.toSetBatchJson());
    setActiveBatch(deviceId, batch);
    final startedAt = _batchStartedAt[deviceId] ?? DateTime.now();
    await _ref.read(firestoreSyncServiceProvider).enqueueBatch(
      batch: batch,
      deviceId: deviceId,
      status: 'active',
      startedAt: startedAt,
    );
  }

  Future<bool> waitForState(
    String deviceId,
    DeviceFsmState expected, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final device = state[deviceId];
      if (device?.estado == expected) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  Future<void> sendEndBatch(String deviceId) async {
    final service = _ref.read(mqttServiceProvider);
    final device = state[deviceId];
    final batch = device?.activeBatch;
    final startedAt = _batchStartedAt[deviceId];
    await service.publishCommand(deviceId, {'cmd': 'END_BATCH'});
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
  }

  Future<void> sendStartCalibration(String deviceId) async {
    final service = _ref.read(mqttServiceProvider);
    await service.publishCommand(deviceId, {'cmd': 'START_CALIBRATION'});
  }

  Future<void> sendOtaUpdate(String deviceId, String url) async {
    final service = _ref.read(mqttServiceProvider);
    await service.publishCommand(deviceId, {'cmd': 'OTA_UPDATE', 'url': url});
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

final labelBufferProvider = StreamProvider<int>((ref) async* {
  final db = ref.watch(databaseProvider);
  while (true) {
    yield await db.labelBufferCount();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
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
