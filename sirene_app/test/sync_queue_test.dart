import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/cloud/models/firestore_mappers.dart';
import 'package:sirene_app/features/cloud/sync/firestore_sync_service.dart';
import 'package:sirene_app/features/cloud/sync/sync_payload_repair.dart';
import 'package:sirene_app/features/cloud/sync/sync_queue_processor.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';

AppDatabase createMemoryDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        return DynamicLibrary.open('libsqlite3.so.0');
      });
    }
  });

  group('SyncQueue', () {
    late AppDatabase db;

    setUp(() {
      db = createMemoryDb();
    });

    tearDown(() async {
      await db.close();
    });

    test('enfileira aprovado em seriais e drena com document_path', () async {
      final written = <String>[];
      final sync = FirestoreSyncService(
        db: db,
        isSyncEnabled: () => true,
        stationId: () => 'posto-test',
      );
      const test = TestResultMessage(
        numeroOp: '2026001',
        idProduto: '123',
        ano: '26',
        veredito: 'APROVADO',
        potenciaMedia: 20.0,
        sequencial: 2,
        aprovadosNoLote: 2,
      );
      final ym = catalogYearMonthFromTimestamp(DateTime.now());
      await sync.enqueueTestResult(
        deviceId: 'abc',
        test: test,
        serial: '12326000028',
      );

      expect(await db.countPending(), 3);

      final processor = SyncQueueProcessor(
        db: db,
        syncService: sync,
        writer: (collection, docId, data, operation, {documentPath}) async {
          written.add('${documentPath ?? '$collection/$docId'}/$operation');
        },
      );
      await processor.processQueue();

      expect(written, [
        'test_results/2026001/merge',
        'test_results/2026001/seriais/12326000028/set',
        'seriais/123/anos/${ym.yyyy}/meses/${ym.mm}/itens/12326000028/set',
      ]);
      expect(await db.countPending(), 0);
    });

    test('reteste aprovado não enfileira serial nem catálogo', () async {
      final sync = FirestoreSyncService(
        db: db,
        isSyncEnabled: () => true,
        stationId: () => 'posto-test',
      );
      const test = TestResultMessage(
        numeroOp: '2026001',
        idProduto: '123',
        ano: '26',
        veredito: 'APROVADO',
        potenciaMedia: 20.0,
        sequencial: 2,
        aprovadosNoLote: 2,
      );
      await sync.enqueueTestResult(
        deviceId: 'abc',
        test: test,
        serial: '12326000028',
        isRetest: true,
      );
      final pending = await db.getPendingItems();
      expect(pending.length, 1);
      expect(pending.single.documentPath, 'test_results/2026001');
      expect(
        pending.any((p) => p.documentPath?.contains('/itens/') == true),
        isFalse,
      );
    });

    test('reprovado não enfileira catálogo temporal', () async {
      final sync = FirestoreSyncService(
        db: db,
        isSyncEnabled: () => true,
        stationId: () => 'posto-test',
      );
      const test = TestResultMessage(
        numeroOp: '2026001',
        idProduto: '123',
        ano: '26',
        veredito: 'REPROVADO',
        potenciaMedia: 5.0,
        sequencial: 3,
        aprovadosNoLote: 1,
      );
      await sync.enqueueTestResult(deviceId: 'abc', test: test);
      final pending = await db.getPendingItems();
      expect(
        pending.any((p) => p.documentPath?.startsWith('seriais/') == true),
        isFalse,
      );
    });

    test('enfileira reprovado em reprovadas', () async {
      final written = <String>[];
      final sync = FirestoreSyncService(
        db: db,
        isSyncEnabled: () => true,
        stationId: () => 'posto-test',
      );
      const test = TestResultMessage(
        numeroOp: '2026001',
        idProduto: '123',
        ano: '26',
        veredito: 'REPROVADO',
        potenciaMedia: 5.0,
        sequencial: 3,
        aprovadosNoLote: 1,
      );
      await sync.enqueueTestResult(deviceId: 'abc', test: test);

      final processor = SyncQueueProcessor(
        db: db,
        syncService: sync,
        writer: (collection, docId, data, operation, {documentPath}) async {
          written.add(documentPath ?? '$collection/$docId');
        },
      );
      await processor.processQueue();

      expect(written, contains('test_results/2026001'));
      expect(written, contains('test_results/2026001/reprovadas/3'));
    });

    test('enfileira delete de produto e drena com operation delete', () async {
      final written = <String>[];
      final sync = FirestoreSyncService(
        db: db,
        isSyncEnabled: () => true,
        stationId: () => 'posto-test',
      );
      await db.upsertProduct(
        idProduto: '071',
        nome: 'Sirene A',
        potenciaRef: 20.0,
        potenciaMin: 18.0,
        potenciaMax: 22.0,
        toleranciaPct: 10,
        tempoTesteSec: 5,
      );
      await sync.enqueueProductDelete('071');

      expect(await db.countPending(), 1);
      final pending = await db.getPendingItems();
      expect(pending.single.operation, 'delete');
      expect(pending.single.collection, 'products');
      expect(pending.single.documentId, '071');

      final processor = SyncQueueProcessor(
        db: db,
        syncService: sync,
        writer: (collection, docId, data, operation, {documentPath}) async {
          written.add('${documentPath ?? '$collection/$docId'}/$operation');
        },
      );
      await processor.processQueue();

      expect(written, ['products/071/delete']);
      expect(await db.countPending(), 0);
    });

    test('resetSyncAttempts move item de dead-letter para pending', () async {
      final id = await db.enqueueSync(
        collection: 'test_results',
        documentId: 'op_1',
        payload: '{}',
        operation: 'set',
      );
      await db.markFailed(id, 'network error', attempts: 5);
      expect(await db.countFailed(), 1);
      expect(await db.countPending(), 0);

      await db.resetSyncAttempts(id);
      expect(await db.countFailed(), 0);
      expect(await db.countPending(), 1);

      final pending = await db.getPendingItems();
      expect(pending.single.id, id);
      expect(pending.single.attempts, 0);
      expect(pending.single.lastError, isNull);
    });

    test('device sem station_id é corrigido na fila e no envio', () async {
      Map<String, dynamic>? sentPayload;
      final sync = FirestoreSyncService(
        db: db,
        isSyncEnabled: () => true,
        stationId: () => 'posto-01',
      );
      final id = await db.enqueueSync(
        collection: 'devices',
        documentId: '841fe83a5db4',
        payload: '{"device_id":"841fe83a5db4","online":true,"updated_by_station":"posto-01"}',
        operation: 'merge',
      );
      await db.markFailed(id, 'permission-denied', attempts: 5);

      final repaired = await repairSyncQueuePayloads(db, 'posto-01', itemId: id);
      expect(repaired, 1);

      final processor = SyncQueueProcessor(
        db: db,
        syncService: sync,
        writer: (collection, docId, data, operation, {documentPath}) async {
          sentPayload = data;
        },
      );
      await db.resetSyncAttempts(id);
      await processor.processQueue();

      expect(sentPayload?['station_id'], 'posto-01');
      expect(await db.countPending(), 0);
    });

    test('enqueueDeviceUpdate inclui station_id no payload', () async {
      final sync = FirestoreSyncService(
        db: db,
        isSyncEnabled: () => true,
        stationId: () => 'posto-01',
      );
      await sync.enqueueDeviceUpdate(
        deviceId: 'abc',
        estado: DeviceFsmState.idle,
        firmwareVersion: '1.0',
        rssi: -50,
        filaOffline: 0,
        online: true,
        force: true,
      );
      final pending = await db.getPendingItems();
      final data = jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expect(data['station_id'], 'posto-01');
    });

    test('processa mais de um lote por ciclo quando há muitos pendentes', () async {
      var written = 0;
      final sync = FirestoreSyncService(
        db: db,
        isSyncEnabled: () => true,
        stationId: () => 'posto-01',
      );
      for (var i = 0; i < 120; i++) {
        await db.enqueueSync(
          collection: 'products',
          documentId: 'p$i',
          payload: '{"id_produto":"p$i","nome":"Produto $i"}',
          operation: 'set',
        );
      }

      final processor = SyncQueueProcessor(
        db: db,
        syncService: sync,
        itemsPerBatch: 50,
        maxBatchesPerRun: 3,
        writer: (collection, docId, data, operation, {documentPath}) async {
          written++;
        },
      );
      await processor.processQueue();

      expect(written, 120);
      expect(await db.countPending(), 0);
    });
  });
}
