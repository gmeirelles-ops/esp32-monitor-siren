import '../../core/config/app_config.dart';

/// Parâmetros de conexão ao broker MQTT (TCP ou WebSocket).
class MqttConnectionConfig {
  const MqttConnectionConfig({
    required this.server,
    required this.port,
    required this.site,
    required this.useWebSocket,
    this.username,
    this.password,
  });

  /// Host TCP ou URL `ws://` / `wss://` com basepath.
  final String server;
  final int port;
  /// Site/ambiente MQTT (ex.: producao).
  final String site;
  final bool useWebSocket;
  final String? username;
  final String? password;

  factory MqttConnectionConfig.fromAppConfig(AppConfig config) {
    return MqttConnectionConfig(
      server: config.mqttClientServer,
      port: config.mqttPort,
      site: config.mqttSite,
      useWebSocket: config.mqttUseWebSocket,
      username: config.mqttUsername.isEmpty ? null : config.mqttUsername,
      password: config.mqttPassword.isEmpty ? null : config.mqttPassword,
    );
  }

  String get logLabel {
    final transport = useWebSocket ? 'WebSocket' : 'TCP';
    return '$site@$server:$port ($transport)';
  }
}
