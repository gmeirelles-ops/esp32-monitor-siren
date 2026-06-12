import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/dashboard/dashboard_filters.dart';
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

  Future<void> addResult(
    String veredito, {
    int seq = 1,
    String numeroOp = '2026001',
    String deviceId = 'aabbccddeeff',
    String? serial,
  }) async {
    await db.insertTestResult(
      deviceId: deviceId,
      numeroOp: numeroOp,
      veredito: veredito,
      potenciaMedia: 20.0,
      sequencial: seq,
      aprovadosNoLote: seq,
      serial: serial,
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

    test('filtra por OP e dispositivo', () async {
      await addResult('APROVADO', numeroOp: 'OP-A');
      await addResult('APROVADO', numeroOp: 'OP-B');
      await addResult('REPROVADO', numeroOp: 'OP-A', deviceId: 'other');

      final byOp = await db.productionSummary(numeroOp: 'OP-A');
      expect(byOp.total, 2);

      final byDevice = await db.productionSummary(deviceId: 'other');
      expect(byDevice.total, 1);
    });

    test('filtra por produto via prefixo do serial', () async {
      await addResult('APROVADO', serial: '1232600011');
      await addResult('APROVADO', serial: '9992600012');

      final filtered = await db.productionSummary(idProduto: '123');
      expect(filtered.total, 1);
    });
  });

  group('throughputByDay', () {
    test('retorna dias conforme período e contabiliza hoje', () async {
      await addResult('APROVADO', seq: 1);
      await addResult('REPROVADO', seq: 2);

      final since = effectiveSinceForPeriod(DashboardPeriod.week);
      final days = throughputDaysForPeriod(DashboardPeriod.week);
      final result = await db.throughputByDay(since: since, days: days);
      expect(result.length, 7);
      final today = result.last;
      expect(today.total, 2);
      expect(today.aprovados, 1);
    });

    test('hoje retorna um único dia', () async {
      await addResult('APROVADO');
      final since = effectiveSinceForPeriod(DashboardPeriod.today);
      final days = throughputDaysForPeriod(DashboardPeriod.today);
      final result = await db.throughputByDay(since: since, days: days);
      expect(result.length, 1);
      expect(result.single.total, 1);
    });

    test('yield por dia calculado corretamente', () async {
      await addResult('APROVADO');
      await addResult('REPROVADO');
      final since = effectiveSinceForPeriod(DashboardPeriod.today);
      final days = await db.throughputByDay(since: since, days: 1);
      final day = days.single;
      expect(day.total, 2);
      expect((day.aprovados / day.total) * 100, 50);
    });
  });

  group('batchSummaryInPeriod', () {
    test('agrupa por OP ordenado por volume', () async {
      await addResult('APROVADO', numeroOp: 'OP-A');
      await addResult('APROVADO', numeroOp: 'OP-A');
      await addResult('REPROVADO', numeroOp: 'OP-B');

      final batches = await db.batchSummaryInPeriod();
      expect(batches.length, 2);
      expect(batches.first.numeroOp, 'OP-A');
      expect(batches.first.total, 2);
      expect(batches.last.numeroOp, 'OP-B');
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
