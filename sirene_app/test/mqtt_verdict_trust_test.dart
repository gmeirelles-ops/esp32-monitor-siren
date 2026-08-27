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

/// Contract 004: app trusts firmware `veredito` from MQTT — no local recalculation.
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
    numeroOp: 'OP-TRUST',
    idProduto: '123',
    ano: '26',
    tempoTeste: 5,
    potenciaMin: 18,
    potenciaMax: 22,
    quantidadeTotal: 10,
    proximoSequencial: 1,
  );

  test('REPROVADO MQTT com potência na faixa não gera serial nem enfileira laser', () async {
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
        potenciaMedia: 20,
        sequencial: 1,
        aprovadosNoLote: 0,
      ),
    );

    final queue = await db.getPendingMarkQueue();
    expect(queue, isEmpty);

    final rows = await db.watchTestsByOp(batch.numeroOp).first;
    expect(rows, hasLength(1));
    expect(rows.single.veredito, 'REPROVADO');
    expect(rows.single.serial, isNull);
  });

  test('APROVADO MQTT gera serial mesmo se limites do lote mudaram depois', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final prefs = await createTestPrefs();
    final container = ProviderContainer(
      overrides: devicesTestOverrides(db: db, prefs: prefs),
    );
    addTearDown(container.dispose);

    final notifier = container.read(devicesProvider.notifier);
    notifier.setActiveBatch(
      'dev1',
      BatchConfig(
        numeroOp: batch.numeroOp,
        idProduto: batch.idProduto,
        ano: batch.ano,
        tempoTeste: batch.tempoTeste,
        potenciaMin: 50,
        potenciaMax: 60,
        quantidadeTotal: batch.quantidadeTotal,
        proximoSequencial: batch.proximoSequencial,
      ),
    );

    await notifier.processTestResult(
      'dev1',
      TestResultMessage(
        numeroOp: batch.numeroOp,
        idProduto: batch.idProduto,
        ano: batch.ano,
        veredito: 'APROVADO',
        potenciaMedia: 20,
        sequencial: 1,
        aprovadosNoLote: 1,
      ),
    );

    final queue = await db.getPendingMarkQueue();
    expect(queue, hasLength(1));
    expect(queue.single.serial, isNotEmpty);
  });
}
