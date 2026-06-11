import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/cloud/sync/firestore_sync_service.dart';
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

    test('enfileira e drena com writer mock', () async {
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
      await sync.enqueueTestResult(deviceId: 'abc', test: test);

      expect(await db.countPending(), 1);

      final processor = SyncQueueProcessor(
        db: db,
        syncService: sync,
        writer: (collection, docId, data, operation) async {
          written.add('$collection/$docId/$operation');
        },
      );
      await processor.processQueue();

      expect(written, ['test_results/2026001_2/set']);
      expect(await db.countPending(), 0);
    });
  });
}
