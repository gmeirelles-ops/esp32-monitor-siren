import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/config/app_config.dart';
import 'package:sirene_app/features/mqtt/mqtt_connection_config.dart';

void main() {
  group('AppConfig MQTT', () {
    test('defaults apontam para broker Diponto via WSS', () async {
      SharedPreferences.setMockInitialValues({});
      final config = AppConfig(await SharedPreferences.getInstance());

      expect(config.mqttHost, 'mqtt.diponto.com');
      expect(config.mqttPort, 443);
      expect(config.mqttSite, 'producao');
      expect(config.mqttWebSocketPath, 'ws');
      expect(config.mqttUseWebSocket, isTrue);
      expect(config.mqttUseTls, isTrue);
      expect(config.mqttUsername, 'devices');
      expect(config.mqttClientServer, 'wss://mqtt.diponto.com/ws');
      expect(config.mqttUri, 'wss://mqtt.diponto.com:443/ws');
    });

    test('MqttConnectionConfig repassa credenciais', () async {
      SharedPreferences.setMockInitialValues({});
      final config = AppConfig(await SharedPreferences.getInstance());
      final mqtt = MqttConnectionConfig.fromAppConfig(config);

      expect(mqtt.server, 'wss://mqtt.diponto.com/ws');
      expect(mqtt.port, 443);
      expect(mqtt.site, 'producao');
      expect(mqtt.useWebSocket, isTrue);
      expect(mqtt.username, 'devices');
      expect(mqtt.password, isNull);
    });

    test('TCP legado sem WebSocket', () async {
      SharedPreferences.setMockInitialValues({
        'mqtt_host': '192.168.1.10',
        'mqtt_port': 1883,
        'mqtt_use_ws': false,
      });
      final config = AppConfig(await SharedPreferences.getInstance());

      expect(config.mqttClientServer, '192.168.1.10');
      expect(config.mqttUri, 'mqtt://192.168.1.10:1883');
    });
  });
}
