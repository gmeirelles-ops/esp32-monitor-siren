import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
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
              manual: const Value('MAN-001'),
              potenciaRef: 20,
              potenciaMin: 18,
              potenciaMax: 22,
            ),
          );
    });

    test('retorna manual cadastrado para gravação', () async {
      final processor = MarkQueueProcessor(
        db: db,
        readConfig: () => AppConfig(prefs),
      );
      await db.addToMarkQueue(serial: '12326000018', numeroOp: '2026001');
      try {
        expect(await processor.simulateDiatuClient(), '12326000018');
        expect(await processor.simulateDiatuManualClient(), 'MAN-001');
      } finally {
        processor.stop();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });

    tearDown(() async {
      await db.close();
    });

    test('serial fica in_progress até pedido de manual confirmar', () async {
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

        final rowAfterSerial = await (db.select(
          db.markQueueEntries,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(rowAfterSerial.status, 'in_progress');

        final model = await processor.simulateDiatuModelClient();
        expect(model, 'Sirene X');

        final rowAfterModel = await (db.select(
          db.markQueueEntries,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(rowAfterModel.status, 'in_progress');

        final manual = await processor.simulateDiatuManualClient();
        expect(manual, 'MAN-001');

        final rowAfterManual = await (db.select(
          db.markQueueEntries,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(rowAfterManual.status, 'delivered');
      } finally {
        processor.stop();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });

    test('produto sem manual conclui a gravação após o modelo', () async {
      await db.upsertProduct(
        idProduto: '124',
        nome: 'Sirene sem manual',
        potenciaRef: 20,
        potenciaMin: 18,
        potenciaMax: 22,
        toleranciaPct: 10,
        tempoTesteSec: 5,
      );
      final processor = MarkQueueProcessor(
        db: db,
        readConfig: () => AppConfig(prefs),
      );
      final id = await db.addToMarkQueue(
        serial: '12426000018',
        numeroOp: '2026001',
      );

      try {
        expect(await processor.simulateDiatuClient(), '12426000018');
        expect(await processor.simulateDiatuModelClient(), 'Sirene sem manual');
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
