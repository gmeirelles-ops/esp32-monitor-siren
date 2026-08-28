/// Versão do contrato JSON MQTT app ↔ firmware (heartbeat / comandos).
///
/// Incrementar quando campos obrigatórios ou semântica mudarem de forma incompatível.
const int kMqttProtocolVersion = 1;

bool mqttProtocolMatches(int? firmwareVersion) {
  if (firmwareVersion == null) return true;
  return firmwareVersion == kMqttProtocolVersion;
}
