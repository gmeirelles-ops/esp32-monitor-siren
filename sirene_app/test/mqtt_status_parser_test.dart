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

  test('parseMqttStatusPayload extrai rejeição', () {
    const payload = '{"tipo":"rejeicao","motivo":"lote_inativo"}';
    final objects = MqttParser.tryParseJsonObjects(payload);
    final result = parseMqttStatusPayload(payload);
    expect(objects, hasLength(1));
    expect(result.rejections, hasLength(1));
    expect(result.rejections.first.motivo, 'lote_inativo');
  });
}
