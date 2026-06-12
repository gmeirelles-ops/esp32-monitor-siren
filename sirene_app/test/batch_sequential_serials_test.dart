import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/batch/batch_serial_logic.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/serial/itf_check_digit.dart';
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
    numeroOp: 'OP-SEQ',
    idProduto: '123',
    ano: '26',
    tempoTeste: 5,
    potenciaMin: 18,
    potenciaMax: 22,
    quantidadeTotal: 10,
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

  TestResultMessage approvedTest(int sequencial, {int aprovadosNoLote = 1}) {
    return TestResultMessage(
      numeroOp: batch.numeroOp,
      idProduto: batch.idProduto,
      ano: batch.ano,
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: sequencial,
      aprovadosNoLote: aprovadosNoLote,
    );
  }

  TestResultMessage rejectedTest(int sequencial) {
    return TestResultMessage(
      numeroOp: batch.numeroOp,
      idProduto: batch.idProduto,
      ano: batch.ano,
      veredito: 'REPROVADO',
      potenciaMedia: 10,
      sequencial: sequencial,
      aprovadosNoLote: 0,
    );
  }

  test('nextBatchSequencial soma aprovados quando lote ainda não avançou', () {
    expect(nextBatchSequencial(batch, aprovadosJaNoLote: 0), 1);
    expect(nextBatchSequencial(batch, aprovadosJaNoLote: 3), 4);
    expect(nextBatchSequencial(batch.copyWith(proximoSequencial: 5)), 5);
  });

  test('4 aprovações simuladas geram 4 seriais distintos no buffer (seq 1..4)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);

    notifier.setActiveBatch('dev1', batch);

    for (var i = 0; i < 4; i++) {
      await notifier.simulateTestResult('dev1', forceApproved: true);
    }

    final buffer = await db.getLabelBuffer();
    expect(buffer, hasLength(4));

    final seriais = buffer.map((e) => e.serial).toList();
    expect(seriais.toSet(), hasLength(4));

    final sequenciais = seriais
        .map((s) => int.parse(s.substring(s.length - 5, s.length - 1)))
        .toList()
      ..sort();
    expect(sequenciais, [1, 2, 3, 4]);

    for (var i = 0; i < 4; i++) {
      expect(
        seriais[i],
        generateFullSerial(idProduto: '123', ano: '26', sequencial: i + 1),
      );
    }
  });

  test('reprovação entre aprovações não pula sequencial de aprovação', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);

    notifier.setActiveBatch('dev1', batch);

    await notifier.processTestResult('dev1', approvedTest(1, aprovadosNoLote: 1));
    await notifier.processTestResult('dev1', rejectedTest(2));
    await notifier.processTestResult('dev1', approvedTest(2, aprovadosNoLote: 2));

    final buffer = await db.getLabelBuffer();
    expect(buffer, hasLength(2));

    final sequenciais = buffer
        .map((e) => int.parse(e.serial.substring(e.serial.length - 5, e.serial.length - 1)))
        .toList()
      ..sort();
    expect(sequenciais, [1, 2]);
  });

  test('activeBatch.proximoSequencial avança após cada emissão', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);

    notifier.setActiveBatch('dev1', batch);

    await notifier.processTestResult('dev1', approvedTest(1));
    expect(container.read(devicesProvider)['dev1']!.activeBatch!.proximoSequencial, 2);

    await notifier.processTestResult('dev1', approvedTest(2, aprovadosNoLote: 2));
    expect(container.read(devicesProvider)['dev1']!.activeBatch!.proximoSequencial, 3);
  });

  test('buffer de etiquetas lista todas as entradas da OP', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);

    notifier.setActiveBatch('dev1', batch);

    for (var i = 0; i < 4; i++) {
      await notifier.simulateTestResult('dev1', forceApproved: true);
    }

    final entries = await db.watchLabelBuffer().first;
    expect(entries, hasLength(4));
    expect(entries.every((e) => e.numeroOp == 'OP-SEQ'), isTrue);
    expect(entries.map((e) => e.serial).toSet(), hasLength(4));
  });
}
