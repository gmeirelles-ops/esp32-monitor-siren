import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../core/constants/mqtt_topics.dart';
import 'models/mqtt_messages.dart';
import 'mqtt_parser.dart';

typedef MqttMessageHandler = void Function(String topic, String payload);

class MqttService {
  MqttService();

  MqttServerClient? _client;
  AppMqttConnectionState _state = AppMqttConnectionState.disconnected;
  final _stateController = StreamController<AppMqttConnectionState>.broadcast();
  final _messageController = StreamController<(String, String)>.broadcast();
  final _rejectionController = StreamController<RejectionMessage>.broadcast();
  final _otaController = StreamController<OtaStatusMessage>.broadcast();
  final _calibrationSampleController =
      StreamController<({String deviceId, CalibrationSampleMessage sample})>.broadcast();
  final _calibrationCompleteController =
      StreamController<({String deviceId, CalibrationMessage result})>.broadcast();

  Timer? _reconnectTimer;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;
  int _backoffSeconds = 1;
  String? _host;
  int? _port;
  MqttMessageHandler? onMessage;

  Stream<AppMqttConnectionState> get connectionState => _stateController.stream;
  Stream<(String, String)> get messages => _messageController.stream;
  Stream<RejectionMessage> get rejections => _rejectionController.stream;
  Stream<OtaStatusMessage> get otaEvents => _otaController.stream;
  Stream<({String deviceId, CalibrationSampleMessage sample})> get calibrationSamples =>
      _calibrationSampleController.stream;
  Stream<({String deviceId, CalibrationMessage result})> get calibrationComplete =>
      _calibrationCompleteController.stream;
  AppMqttConnectionState get currentState => _state;

  Future<void> connect(String host, int port) async {
    _host = host;
    _port = port;
    await _doConnect();
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _detachClient(_client);
    _client = null;
    _setState(AppMqttConnectionState.disconnected);
  }

  void _detachClient(MqttServerClient? client) {
    _updatesSub?.cancel();
    _updatesSub = null;
    if (client == null) return;
    client.onConnected = null;
    client.onDisconnected = null;
    client.disconnect();
  }

  Future<void> publishCommand(String deviceId, Map<String, dynamic> payload) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      throw StateError('MQTT não conectado');
    }
    final topic = MqttTopics.comando(deviceId);
    final builder = MqttClientPayloadBuilder()..addUTF8String(jsonEncode(payload));
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _setState(AppMqttConnectionState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  Future<void> _doConnect() async {
    if (_host == null || _port == null) return;

    _setState(_state == AppMqttConnectionState.disconnected
        ? AppMqttConnectionState.connecting
        : AppMqttConnectionState.reconnecting);

    final oldClient = _client;
    _detachClient(oldClient);
    _client = null;

    final clientId = 'sirene_app_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_host!, clientId, _port!);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 30;
    _client!.autoReconnect = false;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;

    try {
      await _client!.connect();
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _backoffSeconds = 1;
        _setState(AppMqttConnectionState.connected);
      } else {
        _scheduleReconnect();
      }
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    for (final topic in MqttTopics.allSubscriptions) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }
    _updatesSub?.cancel();
    _updatesSub = _client!.updates?.listen(_handleUpdates);
    _setState(AppMqttConnectionState.connected);
    _backoffSeconds = 1;
  }

  void _onDisconnected() {
    if (_state != AppMqttConnectionState.disconnected) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _setState(AppMqttConnectionState.reconnecting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _backoffSeconds), () {
      _backoffSeconds = (_backoffSeconds * 2).clamp(1, 30);
      _doConnect();
    });
  }

  void _handleUpdates(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final topic = event.topic;
      final message = event.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );
      _messageController.add((topic, payload));
      onMessage?.call(topic, payload);

      if (topic.endsWith('/calibracao')) {
        final deviceId = MqttTopics.extractDeviceId(topic);
        if (deviceId != null) {
          final sample = MqttParser.parseCalibrationSample(payload);
          if (sample != null) {
            _calibrationSampleController.add((deviceId: deviceId, sample: sample));
          }
          final result = MqttParser.parseCalibration(payload);
          if (result != null) {
            _calibrationCompleteController.add((deviceId: deviceId, result: result));
          }
        }
      }

      final json = MqttParser.tryParseJson(payload);
      if (json != null) {
        final rejection = MqttParser.parseRejection(json);
        if (rejection != null) {
          _rejectionController.add(rejection);
        }
        final ota = MqttParser.parseOtaStatus(json);
        if (ota != null) {
          _otaController.add(ota);
        }
      }
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _detachClient(_client);
    _client = null;
    _stateController.close();
    _messageController.close();
    _rejectionController.close();
    _otaController.close();
    _calibrationSampleController.close();
    _calibrationCompleteController.close();
  }
}
