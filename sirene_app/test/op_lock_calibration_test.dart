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
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('OP lock', () {
    test('lockOp marca como travada e isOpLocked reflete', () async {
      expect(await db.isOpLocked('2026001'), false);
      await db.lockOp('2026001');
      expect(await db.isOpLocked('2026001'), true);
      expect(await db.isOpLocked('2026002'), false);
    });

    test('lockOp é idempotente', () async {
      await db.lockOp('2026001');
      await db.lockOp('2026001');
      expect(await db.isOpLocked('2026001'), true);
    });
  });

  group('Calibration history', () {
    test('insere e retorna em ordem decrescente', () async {
      await db.insertCalibration(idProduto: '123', potenciaRef: 20.0, deviceId: 'd1');
      await db.insertCalibration(idProduto: '123', potenciaRef: 21.5, deviceId: 'd1');
      await db.insertCalibration(idProduto: '999', potenciaRef: 10.0);

      final history = await db.getCalibrationHistory('123');
      expect(history.length, 2);
      expect(history.first.potenciaRef, 21.5);
      expect(history.last.potenciaRef, 20.0);
    });

    test('watchCalibrationHistory emite após insert', () async {
      final emissions = <List<CalibrationHistoryData>>[];
      final sub = db.watchCalibrationHistory('123').listen(emissions.add);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, isEmpty);

      await db.insertCalibration(idProduto: '123', potenciaRef: 22.0, deviceId: 'd1');
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.length, 1);
      expect(emissions.last.first.potenciaRef, 22.0);
      await sub.cancel();
    });
  });

  group('recentHardwareEvents', () {
    test('respeita limite e ordem desc', () async {
      for (var i = 0; i < 5; i++) {
        await db.insertHardwareEvent(deviceId: 'd1', falha: 'falha_$i');
      }
      final recent = await db.recentHardwareEvents(limit: 3);
      expect(recent.length, 3);
      expect(recent.first.falha, 'falha_4');
    });
  });
}
