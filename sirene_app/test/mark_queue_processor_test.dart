import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sirene_app/core/config/app_config.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/labels/mark_queue_processor.dart';

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

  group('MarkQueueProcessor', () {
    late AppDatabase db;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await AppConfig.migrateBancadaSetupIfNeeded(prefs);
      db = createMemoryDb();
      await prefs.setString('marking_mode', 'laser');
      await prefs.setInt('laser_tcp_port', 19201);
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              idProduto: '123',
              nome: 'Sirene X',
              potenciaRef: 20,
              potenciaMin: 18,
              potenciaMax: 22,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('pedido de serial marca delivered e some da fila pendente', () async {
      final processor = MarkQueueProcessor(
        db: db,
        readConfig: () => AppConfig(prefs),
      );
      final id = await db.addToMarkQueue(
        serial: '12326000018',
        numeroOp: '2026001',
      );

      try {
        final serial = await processor.simulateDiatuClient();
        expect(serial, '12326000018');

        final row = await (db.select(
          db.markQueueEntries,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(row.status, 'delivered');

        final pending = await db.watchPendingMarkQueue().first;
        expect(pending, isEmpty);
      } finally {
        processor.stop();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });

    test('pedido de modelo devolve nome sem alterar fila', () async {
      final processor = MarkQueueProcessor(
        db: db,
        readConfig: () => AppConfig(prefs),
      );
      final id = await db.addToMarkQueue(
        serial: '12326000018',
        numeroOp: '2026001',
      );

      try {
        expect(await processor.simulateDiatuClient(), '12326000018');
        expect(await processor.simulateDiatuModelClient(), 'Sirene X');

        final row = await (db.select(
          db.markQueueEntries,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(row.status, 'delivered');
      } finally {
        processor.stop();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });

    test('requeueAllInProgressMarks recupera fila interrompida', () async {
      final id = await db.addToMarkQueue(
        serial: '12326000019',
        numeroOp: '2026001',
      );
      await db.markQueueInProgress(id);

      final count = await db.requeueAllInProgressMarks();
      expect(count, 1);

      final row = await (db.select(
        db.markQueueEntries,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.status, 'pending');
      expect(row.attempts, 1);
    });
  });
}
