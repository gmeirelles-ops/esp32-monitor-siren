import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
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

  test('ensureBancada atribui números sequenciais', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final n1 = await db.ensureBancada('AA:BB:01');
    final n2 = await db.ensureBancada('AA:BB:02');
    final n1Again = await db.ensureBancada('AA:BB:01');

    expect(n1, 1);
    expect(n2, 2);
    expect(n1Again, 1);
  });

  test('backfill ordena bancadas pelo primeiro teste', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.testResults).insert(
          TestResultsCompanion.insert(
            deviceId: 'DEV-B',
            numeroOp: 'OP-1',
            veredito: 'APROVADO',
            potenciaMedia: 20,
            sequencial: 1,
            aprovadosNoLote: 1,
            createdAt: DateTime(2026, 1, 2),
          ),
        );
    await db.into(db.testResults).insert(
          TestResultsCompanion.insert(
            deviceId: 'DEV-A',
            numeroOp: 'OP-1',
            veredito: 'APROVADO',
            potenciaMedia: 20,
            sequencial: 1,
            aprovadosNoLote: 1,
            createdAt: DateTime(2026, 1, 1),
          ),
        );

    await db.customStatement('DELETE FROM bancadas');
    await db.backfillBancadasFromHistory();

    final rows = await db.getAllBancadasOrdered();
    expect(rows, hasLength(2));
    expect(rows[0].deviceId, 'DEV-A');
    expect(rows[0].numero, 1);
    expect(rows[1].deviceId, 'DEV-B');
    expect(rows[1].numero, 2);
  });
}
