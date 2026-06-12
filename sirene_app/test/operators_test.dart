import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirene_app/core/config/app_config.dart';
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

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('insertOperator persiste operador ativo', () async {
    final id = await db.insertOperator(codigo: '0042', nome: 'Maria');
    final op = await db.getOperatorById(id);
    expect(op, isNotNull);
    expect(op!.codigo, '0042');
    expect(op.nome, 'Maria');
    expect(op.ativo, isTrue);
  });

  test('operatorCodigoExists detecta duplicata', () async {
    await db.insertOperator(codigo: '100', nome: 'João');
    expect(await db.operatorCodigoExists('100'), isTrue);
    expect(await db.operatorCodigoExists('101'), isFalse);
  });

  test('operatorCodigoExists ignora id em edição', () async {
    final id = await db.insertOperator(codigo: '200', nome: 'Ana');
    expect(await db.operatorCodigoExists('200', excludeId: id), isFalse);
  });

  test('watchActiveOperators omite inativos', () async {
    await db.insertOperator(codigo: 'A1', nome: 'Ativo');
    final inactiveId = await db.insertOperator(codigo: 'I1', nome: 'Inativo', ativo: false);
    await db.updateOperator(id: inactiveId, codigo: 'I1', nome: 'Inativo', ativo: false);

    final active = await db.watchActiveOperators().first;
    expect(active, hasLength(1));
    expect(active.single.codigo, 'A1');
  });

  test('processTestResult grava operador ativo local', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final opId = await db.insertOperator(codigo: '77', nome: 'Carlos');

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appConfigProvider).setActiveOperatorId(opId);
    const batch = BatchConfig(
      numeroOp: 'OP-OP',
      idProduto: '123',
      ano: '26',
      tempoTeste: 5,
      potenciaMin: 18,
      potenciaMax: 22,
      quantidadeTotal: 5,
      proximoSequencial: 1,
    );
    final notifier = container.read(devicesProvider.notifier);
    notifier.setActiveBatch('dev1', batch);
    await notifier.processTestResult(
      'dev1',
      const TestResultMessage(
        numeroOp: 'OP-OP',
        idProduto: '123',
        ano: '26',
        veredito: 'REPROVADO',
        potenciaMedia: 15,
        sequencial: 1,
        aprovadosNoLote: 0,
      ),
    );

    final rows = await db.watchTestsByOp('OP-OP').first;
    expect(rows.single.operador, '77 — Carlos');
  });

  test('AppConfig persiste activeOperatorId', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final config = AppConfig(prefs);

    expect(config.activeOperatorId, isNull);
    await config.setActiveOperatorId(7);
    expect(config.activeOperatorId, 7);
    await config.setActiveOperatorId(null);
    expect(config.activeOperatorId, isNull);
  });
}
