import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../core/constants/mqtt_topics.dart';
import '../../core/services/app_log.dart';
import 'models/mqtt_messages.dart';
import 'mqtt_connection_config.dart';
import 'mqtt_parser.dart';

typedef MqttMessageHandler = void Function(String topic, String payload);

class MqttService {
  MqttService();

  String? lastConnectError;

  static MqttService? _active;

  /// Chamado pelo handler global quando o pacote MQTT falha no socket.
  static void handleGlobalAsyncError(Object error, StackTrace stack) {
    final service = _active;
    if (service != null && _looksLikeMqttTransportError(error, stack)) {
      unawaited(AppLog.write('MQTT: recuperando de erro de transporte', error: error, stack: stack));
      service._handleConnectionLost();
      return;
    }
    if (_looksLikeLaserPortError(error)) {
      unawaited(AppLog.write('Laser TCP: porta indisponível (não fatal)', error: error, stack: stack));
      return;
    }
  }

  static bool _looksLikeLaserPortError(Object error) {
    final text = error.toString();
    return text.contains('Porta') && text.contains('em uso');
  }

  static bool _looksLikeMqttTransportError(Object error, StackTrace stack) {
    final text = '$error\n$stack';
    return text.contains('mqtt_client') ||
        text.contains('MqttVariableHeader') ||
        text.contains('MqttConnectAck');
  }

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
  bool _connectInProgress = false;
  MqttConnectionConfig? _connectionConfig;
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

  void emitCalibrationSample(String deviceId, CalibrationSampleMessage sample) {
    _calibrationSampleController.add((deviceId: deviceId, sample: sample));
  }

  void emitCalibrationComplete(String deviceId, CalibrationMessage result) {
    _calibrationCompleteController.add((deviceId: deviceId, result: result));
  }

  @visibleForTesting
  bool testMode = false;

  @visibleForTesting
  final testPublishedCommands = <({int bancadaNum, Map<String, dynamic> payload})>[];

  @visibleForTesting
  set connectionStateForTest(AppMqttConnectionState state) => _state = state;

  Future<void> connect(MqttConnectionConfig config) async {
    _connectionConfig = config;
    _active = this;
    await _doConnect();
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _detachClient(_client);
    _client = null;
    if (_active == this) _active = null;
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

  Future<void> publishCommand(int bancadaNum, Map<String, dynamic> payload) async {
    if (testMode) {
      testPublishedCommands.add((bancadaNum: bancadaNum, payload: payload));
      return;
    }
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      throw StateError('MQTT não conectado');
    }
    final site = _connectionConfig?.site ?? MqttTopics.defaultSite;
    final topic = MqttTopics.comando(site, bancadaNum);
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
    final config = _connectionConfig;
    if (config == null) return;
    if (_connectInProgress) return;
    _connectInProgress = true;

    _setState(_state == AppMqttConnectionState.disconnected
        ? AppMqttConnectionState.connecting
        : AppMqttConnectionState.reconnecting);

    final oldClient = _client;
    _detachClient(oldClient);
    _client = null;

    final clientId = 'sirene_${DateTime.now().millisecondsSinceEpoch % 1000000000}';
    _client = MqttServerClient.withPort(config.server, clientId, config.port);
    _client!.logging(on: false);
    _client!.setProtocolV311();
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = false;
    if (config.useWebSocket) {
      _client!.useWebSocket = true;
      _client!.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
      if (config.server.startsWith('wss://')) {
        // WSS na porta 443: implementação padrão pode interpretar HTTP como MQTT.
        _client!.useAlternateWebSocketImplementation = true;
        _client!.securityContext = SecurityContext.defaultContext;
      }
    }
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;

    try {
      unawaited(AppLog.write('MQTT: conectando ${config.logLabel}'));
      await _client!.connect(config.username, config.password);
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _backoffSeconds = 1;
        lastConnectError = null;
        _setState(AppMqttConnectionState.connected);
        unawaited(AppLog.write('MQTT: conectado'));
      } else {
        lastConnectError = 'código ${_client!.connectionStatus?.returnCode}';
        unawaited(AppLog.write(
          'MQTT: falha na conexão (${_client!.connectionStatus?.returnCode})',
        ));
        _scheduleReconnect();
      }
    } catch (e, st) {
      lastConnectError = e.toString();
      unawaited(AppLog.write('MQTT: erro ao conectar', error: e, stack: st));
      _scheduleReconnect();
    } finally {
      _connectInProgress = false;
    }
  }

  void _onConnected() {
    // O stream `updates` é broadcast: mensagens retidas do broker chegam logo
    // após o SUBACK e são perdidas se o listener ainda não estiver ativo.
    _attachUpdatesListener();
    final site = _connectionConfig?.site ?? MqttTopics.defaultSite;
    for (final topic in MqttTopics.subscriptionsForSite(site)) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }
    _setState(AppMqttConnectionState.connected);
    _backoffSeconds = 1;
  }

  void _attachUpdatesListener() {
    _updatesSub?.cancel();
    _updatesSub = _client!.updates?.listen(
      _handleUpdates,
      onError: (Object e, StackTrace st) {
        unawaited(AppLog.write('MQTT: erro no stream', error: e, stack: st));
        _handleConnectionLost();
      },
    );
  }

  void _handleConnectionLost() {
    if (_state == AppMqttConnectionState.disconnected) return;
    _detachClient(_client);
    _client = null;
    _scheduleReconnect();
  }

  void _onDisconnected() {
    if (_state != AppMqttConnectionState.disconnected) {
      unawaited(AppLog.write('MQTT: desconectado'));
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
    final site = _connectionConfig?.site ?? MqttTopics.defaultSite;
    for (final event in events) {
      final topic = event.topic;
      if (MqttTopics.extractBancadaNum(topic, site: site) == null) continue;
      final message = event.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );
      _messageController.add((topic, payload));
      onMessage?.call(topic, payload);

      final json = MqttParser.tryParseJson(payload);
      if (json != null) {
        final bancadaNum = MqttTopics.extractBancadaNum(topic, site: site);
        final deviceId = MqttTopics.extractDeviceIdFromPayload(json) ??
            (bancadaNum != null ? 'bancada-$bancadaNum' : null);
        final rejection = MqttParser.parseRejection(json);
        if (rejection != null) {
          _rejectionController.add(rejection);
        }
        final ota = MqttParser.parseOtaStatus(json, deviceId: deviceId);
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
    if (_active == this) _active = null;
    _stateController.close();
    _messageController.close();
    _rejectionController.close();
    _otaController.close();
    _calibrationSampleController.close();
    _calibrationCompleteController.close();
  }
}
