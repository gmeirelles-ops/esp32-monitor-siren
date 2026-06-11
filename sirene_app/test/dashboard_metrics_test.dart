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

  Future<void> addResult(String veredito, {int seq = 1}) async {
    await db.insertTestResult(
      deviceId: 'aabbccddeeff',
      numeroOp: '2026001',
      veredito: veredito,
      potenciaMedia: 20.0,
      sequencial: seq,
      aprovadosNoLote: seq,
    );
  }

  group('productionSummary', () {
    test('calcula yield e contagens', () async {
      await addResult('APROVADO', seq: 1);
      await addResult('APROVADO', seq: 2);
      await addResult('APROVADO', seq: 3);
      await addResult('REPROVADO', seq: 4);

      final s = await db.productionSummary();
      expect(s.total, 4);
      expect(s.aprovados, 3);
      expect(s.reprovados, 1);
      expect(s.yieldPct, closeTo(75.0, 0.001));
    });

    test('yield zero sem testes', () async {
      final s = await db.productionSummary();
      expect(s.total, 0);
      expect(s.yieldPct, 0);
    });
  });

  group('throughputByDay', () {
    test('retorna uma entrada por dia e contabiliza hoje', () async {
      await addResult('APROVADO', seq: 1);
      await addResult('REPROVADO', seq: 2);

      final days = await db.throughputByDay(days: 7);
      expect(days.length, 7);
      final today = days.last;
      expect(today.total, 2);
      expect(today.aprovados, 1);
    });
  });

  group('hardwareFaultCounts', () {
    test('agrupa e ordena desc', () async {
      await db.insertHardwareEvent(deviceId: 'd1', falha: 'pzem_offline');
      await db.insertHardwareEvent(deviceId: 'd1', falha: 'pzem_offline');
      await db.insertHardwareEvent(deviceId: 'd2', falha: 'rele_travado');

      final counts = await db.hardwareFaultCounts();
      expect(counts.length, 2);
      expect(counts.first.falha, 'pzem_offline');
      expect(counts.first.count, 2);
      expect(counts.last.falha, 'rele_travado');
    });
  });
}
