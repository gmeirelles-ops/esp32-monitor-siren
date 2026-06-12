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
  });

  group('computeBatchMetrics', () {
    test('yield zero sem testes', () {
      const m = BatchMetrics(total: 0, aprovados: 0, reprovados: 0);
      expect(m.yieldPct, 0);
      expect(m.pendentes(10), 10);
    });
  });
}
