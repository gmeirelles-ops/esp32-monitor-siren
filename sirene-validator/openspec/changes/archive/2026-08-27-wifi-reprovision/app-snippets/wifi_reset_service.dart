// Copiar para sirene_app/lib/features/devices/wifi_reset_service.dart

import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';

/// Publica RESET_WIFI no tópico de comando do dispositivo.
class WifiResetService {
  WifiResetService(this._client, this._deviceId);

  final MqttClient _client;
  final String _deviceId;

  static const apSsid = 'SireneValidator';
  static const apPassword = 'sirene123';
  static const portalUrl = 'http://192.168.4.1';

  Future<void> requestReset({bool clearMqtt = false}) async {
    final topic = 'sirene/$_deviceId/comando';
    final payload = jsonEncode({
      'cmd': 'RESET_WIFI',
      if (clearMqtt) 'clear_mqtt': true,
    });
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
}
