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

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> approve(String serial, {int seq = 1, String op = '2026001'}) async {
    await db.insertTestResult(
      deviceId: 'aabbccddeeff',
      numeroOp: op,
      veredito: 'APROVADO',
      potenciaMedia: 20.0,
      sequencial: seq,
      aprovadosNoLote: seq,
      serial: serial,
    );
  }

  group('SerialCounter', () {
    test('bumpSerialCounter usa max e é idempotente', () async {
      await db.bumpSerialCounter(idProduto: '123', ano: '26', sequencial: 5);
      expect(await db.getLastSequencial('123', '26'), 5);

      await db.bumpSerialCounter(idProduto: '123', ano: '26', sequencial: 3);
      expect(await db.getLastSequencial('123', '26'), 5);

      await db.bumpSerialCounter(idProduto: '123', ano: '26', sequencial: 5);
      expect(await db.getLastSequencial('123', '26'), 5);

      await db.bumpSerialCounter(idProduto: '123', ano: '26', sequencial: 9);
      expect(await db.getLastSequencial('123', '26'), 9);
    });

    test('nextSequencialFor sem e com histórico', () async {
      expect(await db.nextSequencialFor('123', '26'), 1);
      await db.bumpSerialCounter(idProduto: '123', ano: '26', sequencial: 42);
      expect(await db.nextSequencialFor('123', '26'), 43);
      expect(await db.nextSequencialFor('123', '27'), 1);
    });

    test('serialExists detecta serial no histórico', () async {
      expect(await db.serialExists('1232600018'), false);
      await approve('1232600018');
      expect(await db.serialExists('1232600018'), true);
    });

    test('reconcileSerials sequência íntegra', () async {
      await approve('1232600011', seq: 1);
      await approve('1232600029', seq: 2);
      await approve('1232600037', seq: 3);
      final r = await db.reconcileSerials('123', '26');
      expect(r.isIntact, true);
      expect(r.gaps, isEmpty);
      expect(r.duplicates, isEmpty);
      expect(r.found, [1, 2, 3]);
    });

    test('reconcileSerials detecta buraco', () async {
      await approve('1232600011', seq: 1);
      await approve('1232600037', seq: 3);
      final r = await db.reconcileSerials('123', '26');
      expect(r.isIntact, false);
      expect(r.gaps, [2]);
    });

    test('reconcileSerials detecta duplicata', () async {
      await approve('1232600011', seq: 1);
      await approve('1232600011', seq: 1);
      final r = await db.reconcileSerials('123', '26');
      expect(r.isIntact, false);
      expect(r.duplicates, [1]);
    });
  });
}
