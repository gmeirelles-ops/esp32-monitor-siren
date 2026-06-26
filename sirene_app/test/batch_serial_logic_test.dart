import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/batch/batch_serial_logic.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  group('resolveBatchYear', () {
    test('returns two-digit year from DateTime', () {
      expect(resolveBatchYear(DateTime(2026, 6, 16)), '26');
      expect(resolveBatchYear(DateTime(1999, 1, 1)), '99');
      expect(resolveBatchYear(DateTime(2000, 12, 31)), '00');
    });
  });

  group('resolveProximoSequencial', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns 1 when no history', () async {
      expect(await resolveProximoSequencial(db, '123', '26'), 1);
    });

    test('returns last + 1 from SerialCounters', () async {
      await db.bumpSerialCounter(idProduto: '123', ano: '26', sequencial: 5);
      expect(await resolveProximoSequencial(db, '123', '26'), 6);
    });

    test('year rollover uses separate counter key', () async {
      await db.bumpSerialCounter(idProduto: '123', ano: '25', sequencial: 99);
      expect(await resolveProximoSequencial(db, '123', '26'), 1);
    });
  });
}
