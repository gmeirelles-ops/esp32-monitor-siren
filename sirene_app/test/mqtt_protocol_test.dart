import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/constants/mqtt_protocol.dart';

void main() {
  test('kMqttProtocolVersion é positivo', () {
    expect(kMqttProtocolVersion, greaterThan(0));
  });

  test('mqttProtocolMatches aceita null (firmware legado)', () {
    expect(mqttProtocolMatches(null), isTrue);
  });

  test('mqttProtocolMatches compara versão', () {
    expect(mqttProtocolMatches(kMqttProtocolVersion), isTrue);
    expect(mqttProtocolMatches(kMqttProtocolVersion + 1), isFalse);
  });
}
