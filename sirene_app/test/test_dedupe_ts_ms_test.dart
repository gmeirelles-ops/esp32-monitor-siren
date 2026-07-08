import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sqlite3/open.dart';

import 'test_support.dart';

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

  const batch = BatchConfig(
    numeroOp: 'OP-DEDUPE',
    idProduto: '072',
    ano: '26',
    tempoTeste: 15,
    potenciaMin: 18,
    potenciaMax: 22,
    quantidadeTotal: 10,
    proximoSequencial: 500,
  );

  TestResultMessage rejectedTest(int tsMs) {
    return TestResultMessage(
      numeroOp: batch.numeroOp,
      idProduto: batch.idProduto,
      ano: batch.ano,
      veredito: 'REPROVADO',
      potenciaMedia: 10,
      sequencial: 500,
      aprovadosNoLote: 0,
      tsMs: tsMs,
    );
  }

  test('3 reprovados no mesmo sequencial com ts_ms distintos geram 3 registros', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final prefs = await createTestPrefs();
    final container = ProviderContainer(
      overrides: devicesTestOverrides(db: db, prefs: prefs),
    );
    addTearDown(container.dispose);

    final notifier = container.read(devicesProvider.notifier);
    notifier.updateDeviceEstado('dev1', DeviceFsmState.batchReady);
    notifier.setActiveBatch('dev1', batch);

    await notifier.processTestResult('dev1', rejectedTest(1001));
    await notifier.processTestResult('dev1', rejectedTest(1002));
    await notifier.processTestResult('dev1', rejectedTest(1003));

    final rows = await db.testsForOp(batch.numeroOp);
    expect(rows, hasLength(3));
    expect(rows.map((r) => r.firmwareTsMs).toSet(), {1001, 1002, 1003});
  });

  test('replay MQTT com mesmo ts_ms é ignorado', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final prefs = await createTestPrefs();
    final container = ProviderContainer(
      overrides: devicesTestOverrides(db: db, prefs: prefs),
    );
    addTearDown(container.dispose);

    final notifier = container.read(devicesProvider.notifier);
    notifier.updateDeviceEstado('dev1', DeviceFsmState.batchReady);
    notifier.setActiveBatch('dev1', batch);

    final msg = rejectedTest(2001);
    await notifier.processTestResult('dev1', msg);
    await notifier.processTestResult('dev1', msg);

    final rows = await db.testsForOp(batch.numeroOp);
    expect(rows, hasLength(1));
    expect(rows.single.firmwareTsMs, 2001);
  });

  test('mesmo ts_ms com sequencial diferente grava dois registros', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final prefs = await createTestPrefs();
    final container = ProviderContainer(
      overrides: devicesTestOverrides(db: db, prefs: prefs),
    );
    addTearDown(container.dispose);

    final notifier = container.read(devicesProvider.notifier);
    notifier.setActiveBatch('dev1', batch);

    await notifier.processTestResult(
      'dev1',
      TestResultMessage(
        numeroOp: batch.numeroOp,
        idProduto: batch.idProduto,
        ano: batch.ano,
        veredito: 'REPROVADO',
        potenciaMedia: 10,
        sequencial: 500,
        aprovadosNoLote: 0,
        tsMs: 9001,
      ),
    );
    await notifier.processTestResult(
      'dev1',
      TestResultMessage(
        numeroOp: batch.numeroOp,
        idProduto: batch.idProduto,
        ano: batch.ano,
        veredito: 'REPROVADO',
        potenciaMedia: 11,
        sequencial: 501,
        aprovadosNoLote: 0,
        tsMs: 9001,
      ),
    );

    final rows = await db.testsForOp(batch.numeroOp);
    expect(rows, hasLength(2));
  });

  test('insert grava veredito antes de etiqueta (aprovado com serial)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final prefs = await createTestPrefs(useLaserMarking: false);
    final container = ProviderContainer(
      overrides: devicesTestOverrides(db: db, prefs: prefs),
    );
    addTearDown(container.dispose);

    final notifier = container.read(devicesProvider.notifier);
    notifier.updateDeviceEstado('dev1', DeviceFsmState.batchReady);
    notifier.setActiveBatch('dev1', batch);

    final approved = TestResultMessage(
      numeroOp: batch.numeroOp,
      idProduto: batch.idProduto,
      ano: batch.ano,
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 500,
      aprovadosNoLote: 1,
      tsMs: 3001,
    );

    await notifier.processTestResult('dev1', approved);

    final rows = await db.testsForOp(batch.numeroOp);
    expect(rows, hasLength(1));
    expect(rows.single.veredito, 'APROVADO');
    expect(rows.single.serial, isNotNull);
  });
}
