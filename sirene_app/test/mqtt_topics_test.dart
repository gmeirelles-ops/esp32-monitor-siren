import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/constants/mqtt_topics.dart';

void main() {
  group('MqttTopics', () {
    test('bancadaSegment formata com zero à esquerda', () {
      expect(MqttTopics.bancadaSegment(1), 'bancada-01');
      expect(MqttTopics.bancadaSegment(12), 'bancada-12');
    });

    test('monta paths de comando e heartbeat', () {
      expect(MqttTopics.comando('producao', 3), 'producao/bancada-03/comando');
      expect(MqttTopics.heartbeat('producao', 3), 'producao/bancada-03/heartbeat');
    });

    test('extractBancadaNum parseia tópico do site', () {
      expect(
        MqttTopics.extractBancadaNum('producao/bancada-01/heartbeat', site: 'producao'),
        1,
      );
      expect(
        MqttTopics.extractBancadaNum('producao/bancada-12/status', site: 'producao'),
        12,
      );
      expect(
        MqttTopics.extractBancadaNum('homologacao/bancada-01/heartbeat', site: 'producao'),
        isNull,
      );
      expect(MqttTopics.extractBancadaNum('sirene/abc/heartbeat'), isNull);
    });

    test('extractDeviceIdFromPayload lê MAC ou bancada', () {
      expect(
        MqttTopics.extractDeviceIdFromPayload({'device_id': '841fe83a5db4'}),
        '841fe83a5db4',
      );
      expect(
        MqttTopics.extractDeviceIdFromPayload({'bancada': 2}),
        'bancada-02',
      );
      expect(MqttTopics.extractDeviceIdFromPayload({}), isNull);
    });

    test('subscriptionsForSite lista wildcards do ambiente', () {
      expect(
        MqttTopics.subscriptionsForSite('producao'),
        contains('producao/+/heartbeat'),
      );
    });
  });
}
