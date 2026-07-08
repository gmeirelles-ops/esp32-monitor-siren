import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/cloud/models/firestore_mappers.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';

void main() {
  group('FirestoreMappers', () {
    const approvedTest = TestResultMessage(
      numeroOp: '2026001',
      idProduto: '123',
      ano: '26',
      veredito: 'APROVADO',
      potenciaMedia: 20.15,
      sequencial: 1,
      aprovadosNoLote: 1,
    );

    test('gera caminhos hierárquicos lote/seriais/reprovadas', () {
      expect(lotePath('2026001'), 'test_results/2026001');
      expect(serialPath('2026001', '1232600018'),
          'test_results/2026001/seriais/1232600018');
      expect(reprovadaPath('2026001', 3), 'test_results/2026001/reprovadas/3');
      expect(
        reprovadaPath('2026001', 3, tsMs: 6886992),
        'test_results/2026001/reprovadas/6886992',
      );
      expect(
        reprovadaDocumentId(
          const TestResultMessage(
            numeroOp: '2026001',
            idProduto: '123',
            ano: '26',
            veredito: 'REPROVADO',
            potenciaMedia: 5,
            sequencial: 3,
            aprovadosNoLote: 0,
            tsMs: 6886992,
          ),
        ),
        '6886992',
      );
      expect(isReprovadaFirestorePath('test_results/2525/reprovadas/14'), isTrue);
      expect(isReprovadaFirestorePath('test_results/2525/seriais/123'), isFalse);
      expect(isReprovadaFirestorePath(null), isFalse);
    });

    test('mapeia documento de serial aprovado com parâmetros de teste', () {
      final map = mapSerialDocument(
        deviceId: 'aabbccddeeff',
        test: approvedTest,
        serial: '1232600018',
        operador: '001 — João',
        operatorCodigo: '001',
        stationId: 'posto-01',
        timestamp: DateTime.utc(2026, 6, 10, 14, 31),
        tempoTesteSec: 5,
        potenciaMin: 18.0,
        potenciaMax: 22.0,
      );
      expect(map['serial'], '1232600018');
      expect(map['operator_codigo'], '001');
      expect(map['tempo_teste_sec'], 5);
      expect(map['potencia_min'], 18.0);
      expect(map['potencia_max'], 22.0);
    });

    test('mapeia documento reprovado sem serial', () {
      const reprovado = TestResultMessage(
        numeroOp: '2026001',
        idProduto: '123',
        ano: '26',
        veredito: 'REPROVADO',
        potenciaMedia: 5.0,
        sequencial: 3,
        aprovadosNoLote: 1,
      );
      final map = mapReprovadaDocument(
        deviceId: 'aabbccddeeff',
        test: reprovado,
        stationId: 'posto-01',
        timestamp: DateTime.utc(2026, 6, 10, 14, 31),
        isRetest: true,
      );
      expect(map['veredito'], 'REPROVADO');
      expect(map.containsKey('serial'), false);
      expect(map['is_retest'], true);
    });

    test('mapeia documento de lote', () {
      const batch = BatchConfig(
        numeroOp: '2026001',
        idProduto: '123',
        ano: '26',
        tempoTeste: 5,
        quantidadeTotal: 10,
        proximoSequencial: 1,
        potenciaMin: 18,
        potenciaMax: 22,
      );
      final map = mapLoteDocument(
        batch: batch,
        deviceId: 'abc',
        status: 'active',
        stationId: 'posto-01',
        startedAt: DateTime.utc(2026, 6, 10, 10),
      );
      expect(map['numero_op'], '2026001');
      expect(map['status'], 'active');
      expect(map['tempo_teste_sec'], 5);
      expect(map['potencia_min'], 18);
      expect(map['potencia_max'], 22);
    });

    test('mapeia device com station_id exigido pelo Firestore', () {
      final map = mapDevice(
        deviceId: '841fe83a5db4',
        estado: DeviceFsmState.idle,
        firmwareVersion: '1.0.0',
        rssi: -55,
        filaOffline: 0,
        online: true,
        stationId: 'posto-01',
        lastSeen: DateTime.utc(2026, 7, 6, 12),
      );
      expect(map['station_id'], 'posto-01');
      expect(map['updated_by_station'], 'posto-01');
      expect(map['device_id'], '841fe83a5db4');
    });

    test('patchSyncPayloadForFirestore injeta station_id em devices antigos', () {
      final patched = patchSyncPayloadForFirestore(
        collection: 'devices',
        payload: {
          'device_id': '841fe83a5db4',
          'updated_by_station': 'posto-01',
          'online': true,
        },
        stationId: 'posto-01',
      );
      expect(patched['station_id'], 'posto-01');
    });

    test('patchSyncPayloadForFirestore não altera payload com station_id', () {
      final original = {
        'station_id': 'posto-02',
        'numero_op': '2026001',
      };
      final patched = patchSyncPayloadForFirestore(
        collection: 'test_results',
        payload: original,
        stationId: 'posto-01',
        documentPath: 'test_results/2026001',
      );
      expect(identical(patched, original), isTrue);
    });
  });
}
