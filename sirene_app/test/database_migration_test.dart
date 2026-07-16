import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sirene_app/core/database/database.dart';
import 'package:sqlite3/open.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  test('migração 13→15 tolera colunas v14 já existentes', () async {
    final file = File(
      p.join(
        Directory.systemTemp.path,
        'sirene_migration_test_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      ),
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final seed = AppDatabase.forTesting(NativeDatabase(file));
    // Simula banco com schema novo mas user_version desatualizado (migração parcial).
    await seed.customStatement('PRAGMA user_version = 13');
    await seed.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final operators = await db.watchActiveOperators().first;
    expect(operators, isEmpty);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 20);

    final productColumns = await db
        .customSelect('PRAGMA table_info(products)')
        .get();
    expect(
      productColumns.map((row) => row.read<String>('name')),
      contains('manual'),
    );

    final downtimeTable = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='downtime_events'",
        )
        .get();
    expect(downtimeTable, isNotEmpty);

    final ensaioTable = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='ensaio_records'",
        )
        .get();
    expect(ensaioTable, isNotEmpty);
  });
}
