import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/mqtt/mqtt_parser.dart';
import 'package:sirene_app/features/mqtt/mqtt_status_parser.dart';

void main() {
  test('parseMqttStatusPayload extrai teste colado', () {
    const glued =
        '{"tipo":"teste","ts_ms":6886992,"numero_op":"12345","id_produto":"071","ano":"26'
        '{"tipo":"teste","ts_ms":6886992,"numero_op":"12345","id_produto":"071",'
        '"veredito":"APROVADO","potencia_media":37.14,"sequencial":17,"aprovados_no_lote":2}';
    final result = parseMqttStatusPayload(glued);
    expect(result.tests, hasLength(1));
    expect(result.tests.first.veredito, 'APROVADO');
  });

  test('payload colado com campo vazio inválido recupera teste e ano', () {
    const broken =
        r'{"tipo":"teste","ts_ms":6647451,"ts_unix":1783453590,"numero_op":"1320","id_produto":"072","ano":"26{"tipo":"teste","ts_ms":6647451,"ts_unix":1783453590,"numero_op":"1320","id_produto":"072","","veredito":"APROVADO","potencia_media":39.63,"sequencial":502,"aprovados_no_lote":3}';
    final result = parseMqttStatusPayload(broken);
    expect(result.tests, hasLength(1));
    expect(result.tests.first.veredito, 'APROVADO');
    expect(result.tests.first.sequencial, 502);
    expect(result.tests.first.ano, '26');
  });

  test('parseMqttStatusPayload extrai rejeição', () {
    const payload = '{"tipo":"rejeicao","motivo":"lote_inativo"}';
    final objects = MqttParser.tryParseJsonObjects(payload);
    final result = parseMqttStatusPayload(payload);
    expect(objects, hasLength(1));
    expect(result.rejections, hasLength(1));
    expect(result.rejections.first.motivo, 'lote_inativo');
  });

  test('parseMqttStatusPayload extrai lote_cheio', () {
    const payload = '{"tipo":"rejeicao","motivo":"lote_cheio"}';
    final result = parseMqttStatusPayload(payload);
    expect(result.rejections, hasLength(1));
    expect(result.rejections.first.motivo, 'lote_cheio');
  });

  test('parseMqttStatusPayload extrai batch configurado', () {
    const payload =
        '{"tipo":"batch","evento":"configurado","numero_op":"1320","estado":"BATCH_READY"}';
    final result = parseMqttStatusPayload(payload);
    expect(result.batchEvents, hasLength(1));
    expect(result.batchEvents.first.isConfigured, isTrue);
    expect(result.batchEvents.first.numeroOp, '1320');
  });
}
