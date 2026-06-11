import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/cloud/models/firestore_mappers.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';

void main() {
  group('FirestoreMappers', () {
    test('gera document id composto numero_op_sequencial', () {
      expect(testResultDocumentId('2026001', 1), '2026001_1');
      expect(testResultDocumentId('2026042', 15), '2026042_15');
    });

    test('mapeia resultado de teste', () {
      const test = TestResultMessage(
        numeroOp: '2026001',
        idProduto: '123',
        ano: '26',
        veredito: 'APROVADO',
        potenciaMedia: 20.15,
        sequencial: 1,
        aprovadosNoLote: 1,
      );
      final map = mapTestResult(
        deviceId: 'aabbccddeeff',
        test: test,
        serial: '1232600018',
        stationId: 'posto-01',
        timestamp: DateTime.utc(2026, 6, 10, 14, 31),
      );
      expect(map['numero_op'], '2026001');
      expect(map['sequencial'], 1);
      expect(map['serial'], '1232600018');
      expect(map['station_id'], 'posto-01');
    });
  });
}
