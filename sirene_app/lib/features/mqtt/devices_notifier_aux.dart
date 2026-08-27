part of 'mqtt_providers.dart';

mixin _DevicesNotifierAux on _DevicesNotifierBase {
  Future<void> sendStartCalibration(String deviceId, {int? tempoTesteSec}) async {
    final payload = <String, dynamic>{'cmd': 'START_CALIBRATION'};
    if (tempoTesteSec != null && tempoTesteSec >= 1 && tempoTesteSec <= 120) {
      payload['tempo_teste'] = tempoTesteSec;
    }
    await _publishForDevice(deviceId, payload);
  }

  Future<void> sendStartEnsaio(String deviceId, EnsaioConfig config) async {
    await _publishForDevice(deviceId, config.toMqttPayload());
    _setDeviceEstado(deviceId, DeviceFsmState.testing);
  }

  Future<void> sendStopEnsaio(String deviceId) async {
    await _publishForDevice(deviceId, {'cmd': 'STOP_ENSAIO'});
  }

  /// Apaga credenciais Wi-Fi (e opcionalmente broker MQTT) na NVS da bancada.
  /// Retorna motivo de rejeição, ou null se aceito.
  Future<String?> sendResetWifi(String deviceId, {bool clearMqtt = false}) async {
    final service = _ref.read(mqttServiceProvider);
    if (service.currentState != AppMqttConnectionState.connected) {
      return 'mqtt_desconectado';
    }
    await _publishForDevice(deviceId, {
      'cmd': 'RESET_WIFI',
      if (clearMqtt) 'clear_mqtt': true,
    });
    return waitForRejection(deviceId);
  }

  Future<void> sendOtaUpdate(String deviceId, String url) async {
    await _publishForDevice(deviceId, {'cmd': 'OTA_UPDATE', 'url': url});
  }

  /// Envia OTA_UPDATE para vários dispositivos (campanha).
  Future<void> sendOtaCampaign(List<String> deviceIds, String url) async {
    for (final deviceId in deviceIds) {
      await _publishForDevice(deviceId, {'cmd': 'OTA_UPDATE', 'url': url});
    }
  }
}
