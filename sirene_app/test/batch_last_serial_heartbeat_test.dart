import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/constants/mqtt_topics.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/mqtt/mqtt_service.dart';
import 'package:sirene_app/features/serial/itf_check_digit.dart';
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
    numeroOp: 'OP-LAST',
    idProduto: '123',
    ano: '26',
    tempoTeste: 5,
    potenciaMin: 18,
    potenciaMax: 22,
    quantidadeTotal: 3,
    proximoSequencial: 1,
  );

  TestResultMessage approvedTest(int sequencial, {required int aprovadosNoLote}) {
    return TestResultMessage(
      numeroOp: batch.numeroOp,
      idProduto: batch.idProduto,
      ano: batch.ano,
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: sequencial,
      aprovadosNoLote: aprovadosNoLote,
      tsMs: 1000 + sequencial,
    );
  }

  String lastApprovalHeartbeat({
    required int sequencial,
    required int aprovados,
    String estado = 'BATCH_READY',
  }) {
    return '{"device_id":"dev1","bancada":1,"estado":"$estado","numero_op":"${batch.numeroOp}",'
        '"aprovados":$aprovados,"ultimo_veredito":"APROVADO","ultima_potencia":20.0,'
        '"ultimo_sequencial":$sequencial,"ultimo_ts_ms":${2000 + sequencial}}';
  }

  Future<ProviderContainer> createContainer(AppDatabase db) async {
    final prefs = await createTestPrefs();
    final container = ProviderContainer(
      overrides: [
        ...devicesTestOverrides(db: db, prefs: prefs),
        mqttServiceProvider.overrideWithValue(MqttService()..testMode = true),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('último aprovado via heartbeat gera serial antes de encerrar o lote', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await createContainer(db);
    final notifier = container.read(devicesProvider.notifier);

    notifier.setActiveBatch('dev1', batch);
    await notifier.processTestResult('dev1', approvedTest(1, aprovadosNoLote: 1));
    await notifier.processTestResult('dev1', approvedTest(2, aprovadosNoLote: 2));

    final topic = MqttTopics.heartbeat('producao', 1);
    await notifier.handleMessageForTest(
      topic,
      lastApprovalHeartbeat(sequencial: 3, aprovados: 3),
    );

    final rows = await db.watchTestsByOp(batch.numeroOp).first;
    expect(rows, hasLength(3));
    expect(rows.every((r) => r.serial != null && r.serial!.isNotEmpty), isTrue);

    final expectedLast = generateFullSerial(
      idProduto: batch.idProduto,
      ano: batch.ano,
      sequencial: 3,
    );
    expect(rows.map((r) => r.serial), contains(expectedLast));

    final queue = await db.getPendingMarkQueue();
    expect(queue.map((e) => e.serial).toSet(), rows.map((r) => r.serial).toSet());
  });
}
