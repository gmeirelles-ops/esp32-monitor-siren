import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/batch/batch_live_providers.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sqlite3/open.dart';

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
    numeroOp: 'OP-RT',
    idProduto: '123',
    ano: '26',
    tempoTeste: 5,
    potenciaMin: 18,
    potenciaMax: 22,
    quantidadeTotal: 5,
    proximoSequencial: 1,
  );

  Future<ProviderContainer> createContainer(AppDatabase db) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('reteste aprovado não gera serial nem altera métricas', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);

    container.read(retestModeProvider.notifier).state = true;
    notifier.setActiveBatch('dev1', batch.copyWith(modoReteste: true));

    await notifier.processTestResult(
      'dev1',
      const TestResultMessage(
        numeroOp: 'OP-RT',
        idProduto: '123',
        ano: '26',
        veredito: 'APROVADO',
        potenciaMedia: 20,
        sequencial: 1,
        aprovadosNoLote: 0,
      ),
      isRetest: true,
    );

    expect(await db.getLabelBuffer(), isEmpty);
    final metrics = await db.getBatchMetrics('OP-RT');
    expect(metrics.aprovados, 0);
    expect(metrics.total, 0);

    final rows = await db.watchTestsByOp('OP-RT').first;
    expect(rows.single.isRetest, isTrue);
    expect(rows.single.serial, isNull);
  });

  test('auto END_BATCH dispara ao atingir meta', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);

    const smallBatch = BatchConfig(
      numeroOp: 'OP-AUTO',
      idProduto: '123',
      ano: '26',
      tempoTeste: 5,
      potenciaMin: 18,
      potenciaMax: 22,
      quantidadeTotal: 1,
      proximoSequencial: 1,
    );
    notifier.setActiveBatch('dev1', smallBatch);

    await notifier.processTestResult(
      'dev1',
      const TestResultMessage(
        numeroOp: 'OP-AUTO',
        idProduto: '123',
        ano: '26',
        veredito: 'APROVADO',
        potenciaMedia: 20,
        sequencial: 1,
        aprovadosNoLote: 1,
      ),
    );

    expect(container.read(devicesProvider)['dev1']?.activeBatch, isNull);
    expect(container.read(autoBatchEndedProvider)?.numeroOp, 'OP-AUTO');
  });
}
