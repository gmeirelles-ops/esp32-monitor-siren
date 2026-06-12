import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/cloud/models/firestore_mappers.dart';
import 'package:sirene_app/features/cloud/sync/catalog_cloud_service.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  group('productFromFirestore', () {
    test('converte documento completo', () {
      final p = productFromFirestore({
        'id_produto': '123',
        'nome': 'Sirene X',
        'potencia_ref': 20.0,
        'potencia_min': 18.0,
        'potencia_max': 22.0,
        'tolerancia_pct': 10,
        'tempo_teste_sec': 5,
        'calibrado_em': '2026-06-10T14:31:00.000Z',
        'calibrado_device_id': 'aabbccddeeff',
      });
      expect(p, isNotNull);
      expect(p!.idProduto, '123');
      expect(p.nome, 'Sirene X');
      expect(p.potenciaMin, 18.0);
      expect(p.toleranciaPct, 10.0);
      expect(p.tempoTesteSec, 5);
      expect(p.calibradoEm, DateTime.utc(2026, 6, 10, 14, 31));
      expect(p.calibradoDeviceId, 'aabbccddeeff');
    });

    test('aceita DateTime e tipos numéricos mistos', () {
      final p = productFromFirestore({
        'id_produto': '7',
        'potencia_ref': 20,
        'tempo_teste_sec': 5,
        'calibrado_em': DateTime.utc(2026, 1, 1),
      });
      expect(p!.potenciaRef, 20.0);
      expect(p.nome, '');
      expect(p.calibradoEm, DateTime.utc(2026, 1, 1));
    });

    test('retorna null sem id_produto', () {
      expect(productFromFirestore({'nome': 'sem id'}), isNull);
    });
  });

  group('CatalogCloudService', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('pull faz upsert e ignora docs sem id', () async {
      final service = CatalogCloudService(
        db: db,
        reader: () async => [
          {
            'id_produto': '123',
            'nome': 'Sirene X',
            'potencia_ref': 20.0,
            'potencia_min': 18.0,
            'potencia_max': 22.0,
            'tolerancia_pct': 10.0,
            'tempo_teste_sec': 5,
          },
          {'nome': 'invalido sem id'},
        ],
      );

      final applied = await service.pull();
      expect(applied, 1);

      final stored = await db.getProduct('123');
      expect(stored, isNotNull);
      expect(stored!.nome, 'Sirene X');
      expect(stored.potenciaMax, 22.0);
    });
  });

  group('busca de serial', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('findTestResultBySerial e searchSerials', () async {
      await db.insertTestResult(
        deviceId: 'aabbccddeeff',
        numeroOp: '2026001',
        veredito: 'APROVADO',
        potenciaMedia: 20.0,
        sequencial: 1,
        aprovadosNoLote: 1,
        serial: '1232600018',
      );

      final exact = await db.findTestResultBySerial('1232600018');
      expect(exact, isNotNull);
      expect(exact!.numeroOp, '2026001');

      final partial = await db.searchSerials('26000');
      expect(partial.length, 1);

      final none = await db.findTestResultBySerial('0000000000');
      expect(none, isNull);
    });
  });
}
