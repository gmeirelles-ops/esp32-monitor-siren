import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/constants/mqtt_topics.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/mqtt/mqtt_service.dart';
import 'package:sirene_app/features/serial/itf_check_digit.dart';
import 'package:sqlite3/open.dart';

import 'test_support.dart';

/// Sprint A — constitution P0 fixes (R02–R04).
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
    numeroOp: 'OP-SA',
    idProduto: '123',
    ano: '26',
    tempoTeste: 5,
    potenciaMin: 18,
    potenciaMax: 22,
    quantidadeTotal: 10,
    proximoSequencial: 1,
  );

  Future<ProviderContainer> createContainer(
    AppDatabase db, {
    AppMqttConnectionState mqttState = AppMqttConnectionState.connected,
    Map<String, DeviceInfo> devices = const {},
  }) async {
    final prefs = await createTestPrefs();
    final mqtt = MqttService()
      ..testMode = true
      ..connectionStateForTest = mqttState;
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        mqttServiceProvider.overrideWithValue(mqtt),
        devicesProvider.overrideWith(
          (ref) => DevicesNotifier.forTesting(ref, Map<String, DeviceInfo>.from(devices)),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('sendEndBatch retorna mqtt_desconectado quando broker offline', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(
      db,
      mqttState: AppMqttConnectionState.disconnected,
    );
    final notifier = container.read(devicesProvider.notifier);
    notifier.setActiveBatch('dev1', batch);

    final rejection = await notifier.sendEndBatch('dev1');

    expect(rejection, 'mqtt_desconectado');
    expect(container.read(devicesProvider)['dev1']?.activeBatch, isNotNull);
  });

  test('firmware encerrado finaliza lote com lockOp e limpa sessão', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.syncBancadaFromFirmware('dev1', 1);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);
    notifier.setActiveBatch('dev1', batch);

    final topic = MqttTopics.status(MqttTopics.defaultSite, 1);
    await notifier.handleMessageForTest(
      topic,
      '{"tipo":"batch","evento":"encerrado","motivo":"operador"}',
    );

    expect(container.read(devicesProvider)['dev1']?.activeBatch, isNull);
    expect(await db.isOpLocked(batch.numeroOp), isTrue);
  });

  test('serial duplicado bloqueia insert de aprovação', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);
    notifier.setActiveBatch('dev1', batch);

    final dupSerial = generateFullSerial(
      idProduto: batch.idProduto,
      ano: batch.ano,
      sequencial: 2,
    );
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-OTHER',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 1,
      aprovadosNoLote: 1,
      serial: dupSerial,
    );

    await notifier.processTestResult(
      'dev1',
      TestResultMessage(
        numeroOp: batch.numeroOp,
        idProduto: batch.idProduto,
        ano: batch.ano,
        veredito: 'APROVADO',
        potenciaMedia: 20,
        sequencial: 2,
        aprovadosNoLote: 1,
        tsMs: 9999,
      ),
    );

    final rows = await db.watchTestsByOp(batch.numeroOp).first;
    expect(rows, isEmpty);
  });
}
