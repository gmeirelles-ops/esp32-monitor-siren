import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/serial/itf_check_digit.dart';
import 'package:sirene_app/features/serial/manual_serial_service.dart';
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

  test('previewManualSerial usa contador do produto', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertProduct(
      idProduto: '072',
      nome: 'Sirene X',
      potenciaRef: 20,
      potenciaMin: 18,
      potenciaMax: 22,
      toleranciaPct: 5,
      tempoTesteSec: 10,
      sequencialInicial: 100,
    );
    await db.bumpSerialCounter(idProduto: '072', ano: '26', sequencial: 105);

    final preview = await previewManualSerial(db, idProduto: '072', sequencialInicial: 100);
    expect(preview.sequencial, 106);
    expect(preview.serial, startsWith('07226'));
    expect(preview.serial.length, 10);
  });

  test('issueManualSerialCore enfileira laser e grava contador', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertProduct(
      idProduto: '071',
      nome: 'Produto teste',
      potenciaRef: 35,
      potenciaMin: 30,
      potenciaMax: 40,
      toleranciaPct: 5,
      tempoTesteSec: 5,
    );

    final product = (await db.watchProducts().first).first;

    final issue = await issueManualSerialCore(
      db: db,
      product: product,
      numeroOp: 'GRAV-TEST',
    );

    expect(issue.serial.length, 10);
    expect(issue.modelo, 'Produto teste');
    expect(await db.serialExists(issue.serial), isTrue);
    expect(await db.markQueueContainsSerial(issue.serial), isTrue);

    final rows = await db.searchSerials(issue.serial);
    expect(rows, hasLength(1));
    expect(rows.single.veredito, 'MANUAL');
  });

  test('serialExists inclui fila de gravação', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.addToMarkQueue(serial: '07126000107', numeroOp: 'MANUAL');
    expect(await db.serialExists('07126000107'), isTrue);
  });

  test('issueManualSerialCore aceita serial editado manualmente', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertProduct(
      idProduto: '037',
      nome: 'DP300 220V',
      potenciaRef: 35,
      potenciaMin: 30,
      potenciaMax: 40,
      toleranciaPct: 5,
      tempoTesteSec: 5,
      sequencialInicial: 1,
    );

    final product = (await db.watchProducts().first).first;
    final customSerial = generateFullSerial(
      idProduto: '037',
      ano: '26',
      sequencial: 99,
    );

    final issue = await issueManualSerialCore(
      db: db,
      product: product,
      serialOverride: customSerial,
    );

    expect(issue.serial, customSerial);
    expect(issue.sequencial, 99);
    expect(await db.markQueueContainsSerial(customSerial), isTrue);
  });

  test('issueManualSerialBatchCore gera quantidade consecutiva', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertProduct(
      idProduto: '037',
      nome: 'DP300',
      potenciaRef: 35,
      potenciaMin: 30,
      potenciaMax: 40,
      toleranciaPct: 5,
      tempoTesteSec: 5,
      sequencialInicial: 1,
    );
    final product = (await db.watchProducts().first).first;

    final issues = await issueManualSerialBatchCore(
      db: db,
      product: product,
      quantity: 3,
    );

    expect(issues, hasLength(3));
    expect(issues[0].sequencial, 1);
    expect(issues[2].sequencial, 3);
    expect(await db.markQueueContainsSerial(issues[0].serial), isTrue);
    expect(await db.markQueueContainsSerial(issues[2].serial), isTrue);
  });

  test('issueManualSerialBatchCore aceita quantidade acima de 50', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertProduct(
      idProduto: '037',
      nome: 'DP300',
      potenciaRef: 35,
      potenciaMin: 30,
      potenciaMax: 40,
      toleranciaPct: 5,
      tempoTesteSec: 5,
      sequencialInicial: 1,
    );
    final product = (await db.watchProducts().first).first;

    final issues = await issueManualSerialBatchCore(
      db: db,
      product: product,
      quantity: 75,
    );

    expect(issues, hasLength(75));
    expect(issues.first.sequencial, 1);
    expect(issues.last.sequencial, 75);
  });

  test('issueManualSerialCore rejeita serial com dígito inválido', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertProduct(
      idProduto: '071',
      nome: 'Produto',
      potenciaRef: 35,
      potenciaMin: 30,
      potenciaMax: 40,
      toleranciaPct: 5,
      tempoTesteSec: 5,
    );
    final product = (await db.watchProducts().first).first;

    expect(
      () => issueManualSerialCore(
        db: db,
        product: product,
        serialOverride: '07126000000',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('issueManualSerialCore rejeita quando serial já existe', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertProduct(
      idProduto: '071',
      nome: 'Produto',
      potenciaRef: 35,
      potenciaMin: 30,
      potenciaMax: 40,
      toleranciaPct: 5,
      tempoTesteSec: 5,
    );
    final product = (await db.watchProducts().first).first;
    final preview = await previewManualSerial(db, idProduto: product.idProduto);

    await db.addToMarkQueue(serial: preview.serial, numeroOp: 'MANUAL');

    expect(
      () => issueManualSerialCore(db: db, product: product),
      throwsA(isA<StateError>()),
    );
  });
}
