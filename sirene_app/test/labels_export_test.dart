import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/labels/zpl_generator.dart';
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

  test('gerar ZPL para exportação não remove buffer', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.addLabelToBuffer(serial: '1232600101', numeroOp: 'OP-1');
    await db.addLabelToBuffer(serial: '1232600201', numeroOp: 'OP-1');

    final before = await db.getLabelBuffer();
    final zpl = generateZplForSerials(before.map((e) => e.serial).toList());
    final after = await db.getLabelBuffer();

    expect(zpl, contains('^XA'));
    expect(zpl, contains('^XZ'));
    expect(after, hasLength(before.length));
  });

  test('generateZplForSerials concatena blocos para 6 seriais', () {
    final serials = List.generate(6, (i) => '123260000${i + 1}');
    final zpl = generateZplForSerials(serials);

    expect('^XA'.allMatches(zpl).length, 2);
    expect('^XZ'.allMatches(zpl).length, 2);
    for (final s in serials) {
      expect(zpl, contains(s));
    }
  });
}
