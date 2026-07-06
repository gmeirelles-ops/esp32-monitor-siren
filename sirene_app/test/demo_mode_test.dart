import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/demo/demo_constants.dart';
import 'package:sirene_app/features/demo/demo_providers.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/operators/operators_provider.dart';
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

  ProviderContainer buildContainer(AppDatabase db, SharedPreferences prefs) {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        devicesProvider.overrideWith(
          (ref) => DevicesNotifier.forTesting(ref, {}),
        ),
      ],
    );
  }

  test('sendSetBatch em demo mode não exige MQTT', () async {
    SharedPreferences.setMockInitialValues({'demo_mode_enabled': true});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final container = buildContainer(db, prefs);
    addTearDown(container.dispose);
    addTearDown(db.close);

    const batch = BatchConfig(
      numeroOp: 'DEMO-01',
      idProduto: '071',
      ano: '26',
      tempoTeste: 5,
      potenciaMin: 30,
      potenciaMax: 40,
      quantidadeTotal: 5,
      proximoSequencial: 1,
    );

    final rejection = await container
        .read(devicesProvider.notifier)
        .sendSetBatch(kDemoDeviceId, batch);

    expect(rejection, isNull);
    final device = container.read(devicesProvider)[kDemoDeviceId];
    expect(device?.isOnline, isTrue);
    expect(device?.activeBatch?.numeroOp, 'DEMO-01');
    expect(device?.estado, DeviceFsmState.batchReady);
  });

  test('simulateTestResult em demo usa operador da sessão quando disponível', () async {
    SharedPreferences.setMockInitialValues({'demo_mode_enabled': true});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final operatorId = await db.insertOperator(codigo: '9999', nome: 'Apresentador');

    final container = buildContainer(db, prefs);
    addTearDown(container.dispose);
    addTearDown(db.close);
    container.read(sessionOperatorIdProvider.notifier).state = operatorId;

    const batch = BatchConfig(
      numeroOp: 'DEMO-02',
      idProduto: '071',
      ano: '26',
      tempoTeste: 5,
      potenciaMin: 30,
      potenciaMax: 40,
      quantidadeTotal: 5,
      proximoSequencial: 1,
    );

    final notifier = container.read(devicesProvider.notifier);
    await notifier.sendSetBatch(kDemoDeviceId, batch);
    await notifier.simulateTestResult(kDemoDeviceId, forceApproved: true);

    final rows = await db.watchTestsByOp('DEMO-02').first;
    expect(rows, hasLength(1));
    expect(rows.single.veredito, 'APROVADO');
    expect(rows.single.operador, 'Apresentador');
  });
}
