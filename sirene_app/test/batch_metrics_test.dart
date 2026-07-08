import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/batch_metrics.dart';
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

  Future<void> addResult(String veredito, {String op = 'OP-100'}) async {
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: op,
      veredito: veredito,
      potenciaMedia: 20.0,
      sequencial: 1,
      aprovadosNoLote: 1,
    );
  }

  group('getBatchMetrics', () {
    test('filtra por numero_op', () async {
      await addResult('APROVADO', op: 'OP-A');
      await addResult('REPROVADO', op: 'OP-A');
      await addResult('APROVADO', op: 'OP-B');

      final metricsA = await db.getBatchMetrics('OP-A');
      expect(metricsA.total, 2);
      expect(metricsA.aprovados, 1);
      expect(metricsA.reprovados, 1);
      expect(metricsA.yieldPct, 50);
      expect(metricsA.pendentes(5), 4);
    });

    test('exclui testes marcados como reteste', () async {
      await addResult('APROVADO', op: 'OP-R');
      await db.insertTestResult(
        deviceId: 'dev1',
        numeroOp: 'OP-R',
        veredito: 'APROVADO',
        potenciaMedia: 20,
        sequencial: 2,
        aprovadosNoLote: 0,
        isRetest: true,
      );

      final metrics = await db.getBatchMetrics('OP-R');
      expect(metrics.total, 1);
      expect(metrics.aprovados, 1);
    });
  });

  group('computeBatchMetrics', () {
    test('yield zero sem testes', () {
      const m = BatchMetrics(total: 0, aprovados: 0, reprovados: 0);
      expect(m.yieldPct, 0);
      expect(m.pendentes(10), 10);
    });
  });

  group('resolveFirmwareAprovados', () {
    test('usa o maior entre heartbeat e último teste', () {
      expect(
        resolveFirmwareAprovados(heartbeat: 5, lastTest: 6),
        6,
      );
      expect(resolveFirmwareAprovados(heartbeat: 6), 6);
      expect(resolveFirmwareAprovados(lastTest: 4), 4);
      expect(resolveFirmwareAprovados(), isNull);
    });
  });

  group('mergeFirmwareAprovados', () {
    test('alinha aprovados com contador da bancada', () {
      const db = BatchMetrics(total: 2, aprovados: 2, reprovados: 0);
      final merged = mergeFirmwareAprovados(db, 6);
      expect(merged.aprovados, 6);
      expect(merged.total, 6);
      expect(merged.reprovados, 0);
      expect(merged.pendentes(10), 4);
    });

    test('não altera quando firmware está atrás do SQLite', () {
      const db = BatchMetrics(total: 6, aprovados: 6, reprovados: 0);
      expect(mergeFirmwareAprovados(db, 4), db);
    });
  });

  group('computeSessionBatchMetrics', () {
    test('ignora testes anteriores à sessão', () {
      final old = TestResult(
        id: 1,
        deviceId: 'd1',
        numeroOp: 'OP1',
        veredito: 'APROVADO',
        potenciaMedia: 20,
        sequencial: 1,
        aprovadosNoLote: 1,
        serial: 's1',
        operador: 'op',
        tempoTesteSec: 5,
        potenciaMin: 18,
        potenciaMax: 22,
        operatorId: null,
        isRetest: false,
        firmwareTsMs: null,
        createdAt: DateTime(2020, 1, 1),
      );
      final recent = TestResult(
        id: 2,
        deviceId: 'd1',
        numeroOp: 'OP1',
        veredito: 'APROVADO',
        potenciaMedia: 21,
        sequencial: 2,
        aprovadosNoLote: 2,
        serial: 's2',
        operador: 'op',
        tempoTesteSec: 5,
        potenciaMin: 18,
        potenciaMax: 22,
        operatorId: null,
        isRetest: false,
        firmwareTsMs: null,
        createdAt: DateTime.now(),
      );
      final metrics = computeSessionBatchMetrics(
        [old, recent],
        since: DateTime(2026, 1, 1),
      );
      expect(metrics.aprovados, 1);
      expect(metrics.total, 1);
    });
  });
}
