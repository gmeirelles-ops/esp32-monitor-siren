import 'models/mqtt_messages.dart';
import 'mqtt_parser.dart';

/// Resultado do parse de payloads no tópico `/status`.
class MqttStatusParseResult {
  const MqttStatusParseResult({
    this.rejections = const [],
    this.tests = const [],
    this.batchEvents = const [],
  });

  final List<RejectionMessage> rejections;
  final List<TestResultMessage> tests;
  final List<BatchEventMessage> batchEvents;
}

MqttStatusParseResult parseMqttStatusPayload(String payload) {
  final rejections = <RejectionMessage>[];
  final tests = <TestResultMessage>[];
  final batchEvents = <BatchEventMessage>[];
  for (final json in MqttParser.tryParseJsonObjects(payload)) {
    final rejection = MqttParser.parseRejection(json);
    if (rejection != null) rejections.add(rejection);
    final test = MqttParser.parseTestResult(json);
    if (test != null) tests.add(test);
    final batch = MqttParser.parseBatchEvent(json);
    if (batch != null) batchEvents.add(batch);
  }
  return MqttStatusParseResult(
    rejections: rejections,
    tests: tests,
    batchEvents: batchEvents,
  );
}
