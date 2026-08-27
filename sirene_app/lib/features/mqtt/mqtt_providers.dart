import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/mqtt_topics.dart';
import '../../core/database/batch_metrics.dart';
import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/app_log.dart';
import '../../core/utils/device_stale.dart';
import '../cloud/sync/sync_providers.dart';
import '../labels/marking_providers.dart';
import '../labels/serial_marking_backend.dart';
import '../serial/itf_check_digit.dart';
import 'message_pump.dart';
import 'mqtt_status_parser.dart';
import '../../shared/widgets/rejection_labels.dart';
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

part 'devices_notifier_inbound.dart';
part 'devices_notifier_test_pipeline.dart';
part 'devices_notifier_batch.dart';
part 'devices_notifier_aux.dart';

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

typedef DeviceNvsFaultEvent = ({String deviceId, NvsFaultAlertMessage alert});

final latestNvsFaultProvider = StateProvider<DeviceNvsFaultEvent?>((ref) => null);

typedef DuplicateSerialEvent = ({String deviceId, String serial});

final duplicateSerialProvider = StateProvider<DuplicateSerialEvent?>((ref) => null);

final devicesProvider =
    StateNotifierProvider<DevicesNotifier, Map<String, DeviceInfo>>((ref) {
  return DevicesNotifier(ref);
});

/// Shared fields/helpers for [DevicesNotifier] mixins (same library).
abstract class _DevicesNotifierBase extends StateNotifier<Map<String, DeviceInfo>> {
  _DevicesNotifierBase(this._ref, Map<String, DeviceInfo> devices) : super(devices);

  final Ref _ref;
  StreamSubscription<(String, String)>? _sub;
  Timer? _staleTimer;
  final MessagePump _messagePump = MessagePump();
  final Map<String, DateTime> _batchStartedAt = {};
  final Map<String, int> _rejectionEpoch = {};
  final Map<String, int> _batchAckEpoch = {};
  final Set<String> _autoEndBatchSent = {};
  final Map<int, String> _bancadaToDeviceId = {};
  final Map<String, Timer> _verdictWatchdogTimers = {};
  final Map<String, Timer> _cooldownRejectionTimers = {};

  static const _verdictWatchdogDuration = Duration(seconds: 15);

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

  // Cross-mixin hooks (implemented in part mixins).
  void _cancelVerdictWatchdog(String deviceId);
  void _clearRejectionAfterTest(String deviceId);
  void _setDeviceEstado(String deviceId, DeviceFsmState estado);
  Future<String?> waitForRejection(String deviceId, {Duration timeout});
  Future<bool> waitForBatchConfigured(String deviceId, {Duration timeout});
  Future<void> processTestResult(
    String deviceId,
    TestResultMessage test, {
    String? operador,
    bool? isRetest,
  });
  Future<void> _ensureMarkingForTest(AppDatabase db, TestResultMessage test);
  Future<void> _syncMarkingForOp(AppDatabase db, String numeroOp, {DateTime? since});
  Future<void> _ensureMarkServerForOp();
  void ensureDemoDevice(String deviceId);
  Future<void> _maybeAutoEndBatch(String deviceId, {TestResultMessage? test});
  void _advanceBatchSequencial(String deviceId, TestResultMessage test);
  Future<void> _finalizeBatchLocally(String deviceId);
}

class DevicesNotifier extends _DevicesNotifierBase
    with
        _DevicesNotifierInbound,
        _DevicesNotifierTestPipeline,
        _DevicesNotifierBatch,
        _DevicesNotifierAux {
  DevicesNotifier(Ref ref, {bool enableMqtt = true}) : super(ref, {}) {
    if (enableMqtt) _init();
  }

  /// Instância sem MQTT para testes de widget.
  @visibleForTesting
  DevicesNotifier.forTesting(Ref ref, Map<String, DeviceInfo> devices)
      : super(ref, devices);

  /// Processa mensagem MQTT (testes de integração).
  @visibleForTesting
  Future<void> handleMessageForTest(String topic, String payload) =>
      _handleMessage((topic, payload));

  /// Operador gravado pelo simulador de desenvolvimento (não-demo).
  static const devSimulatorOperador = 'dev-simulator';

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

  @override
  void dispose() {
    _sub?.cancel();
    _staleTimer?.cancel();
    for (final t in _verdictWatchdogTimers.values) {
      t.cancel();
    }
    _verdictWatchdogTimers.clear();
    for (final t in _cooldownRejectionTimers.values) {
      t.cancel();
    }
    _cooldownRejectionTimers.clear();
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
