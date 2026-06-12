import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
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

  test('simulateTestResult grava teste com operador dev-simulator', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    final batch = const BatchConfig(
      numeroOp: 'OP-SIM',
      idProduto: '123',
      ano: '26',
      tempoTeste: 5,
      potenciaMin: 18,
      potenciaMax: 22,
      quantidadeTotal: 10,
      proximoSequencial: 1,
    );

    container.read(devicesProvider.notifier).setActiveBatch('dev1', batch);
    await container.read(devicesProvider.notifier).simulateTestResult('dev1');

    final metrics = await db.getBatchMetrics('OP-SIM');
    expect(metrics.total, 1);

    final rows = await db.watchTestsByOp('OP-SIM').first;
    expect(rows.single.operador, DevicesNotifier.devSimulatorOperador);
    expect(rows.single.numeroOp, 'OP-SIM');
  });
}
