// Copiar para sirene_app — cancelar lote ativo

import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';

class BatchCancelService {
  BatchCancelService(this._client, this._deviceId);

  final MqttClient _client;
  final String _deviceId;

  /// Encerra o lote no ESP32 (vai para IDLE). Aceita END_BATCH ou CANCEL_BATCH.
  Future<void> cancelBatch() async {
    final topic = 'sirene/$_deviceId/comando';
    final payload = jsonEncode({'cmd': 'CANCEL_BATCH'});
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
}
