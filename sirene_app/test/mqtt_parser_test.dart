import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/mqtt/mqtt_parser.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';

void main() {
  group('MqttParser', () {
    test('parseia heartbeat', () {
      final hb = MqttParser.parseHeartbeat(
        '{"uptime":3600,"rssi":-62,"estado":"BATCH_READY","fila":0,"firmware_version":"1.1.0"}',
      );
      expect(hb, isNotNull);
      expect(hb!.estado, DeviceFsmState.batchReady);
      expect(hb.firmwareVersion, '1.1.0');
    });

    test('parseia resultado de teste', () {
      final json = MqttParser.tryParseJson(
        '{"tipo":"teste","numero_op":"2026001","id_produto":"123","ano":"26",'
        '"veredito":"APROVADO","potencia_media":20.15,"sequencial":1,"aprovados_no_lote":1}',
      )!;
      final test = MqttParser.parseTestResult(json);
      expect(test!.isApproved, isTrue);
      expect(test.potenciaMedia, closeTo(20.15, 0.01));
    });

    test('parseia rejeição', () {
      final json = MqttParser.tryParseJson('{"tipo":"rejeicao","motivo":"json_invalido"}')!;
      final rejection = MqttParser.parseRejection(json);
      expect(rejection!.motivo, 'json_invalido');
    });

    test('parseia alerta de hardware com falha', () {
      final alert = MqttParser.parseHardwareAlert('{"tipo":"hardware","falha":"pzem_uart"}');
      expect(alert, isNotNull);
      expect(alert!.falha, 'pzem_uart');
      expect(alert.isRecovery, isFalse);
    });

    test('parseia alerta de recuperação de hardware', () {
      final alert = MqttParser.parseHardwareAlert('{"tipo":"hardware","evento":"recuperado"}');
      expect(alert, isNotNull);
      expect(alert!.isRecovery, isTrue);
    });

    test('parseia amostra de calibração', () {
      final sample = MqttParser.parseCalibrationSample(
        '{"tipo":"calibracao_amostra","potencia_w":20.1,"elapsed_ms":1500}',
      );
      expect(sample, isNotNull);
      expect(sample!.potenciaW, closeTo(20.1, 0.01));
      expect(sample.elapsedMs, 1500);
    });

    test('parseia resultado final de calibração', () {
      final cal = MqttParser.parseCalibration(
        '{"tipo":"calibracao","potencia_media":20.15}',
      );
      expect(cal, isNotNull);
      expect(cal!.potenciaMedia, closeTo(20.15, 0.01));
    });

    test('retorna null para JSON malformado', () {
      expect(MqttParser.tryParseJson('not json'), isNull);
    });
  });
}
