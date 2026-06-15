import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/core/database/veredito.dart';

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

  Future<void> seedProduct() async {
    await db.upsertProduct(
      idProduto: '123',
      nome: 'Sirene X',
      potenciaRef: 20,
      potenciaMin: 18,
      potenciaMax: 22,
      toleranciaPct: 10,
      tempoTesteSec: 5,
    );
  }

  test('getTraceabilityBySerial retorna null para serial inexistente', () async {
    expect(await db.getTraceabilityBySerial('1234567890'), isNull);
  });

  test('getTraceabilityBySerial agrega tentativas e produto', () async {
    await seedProduct();
    const serial = '12326000015';

    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-1',
      veredito: 'REPROVADO',
      potenciaMedia: 15,
      sequencial: 1,
      aprovadosNoLote: 0,
      serial: serial,
      operador: '01 — Ana',
    );
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-1',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 1,
      aprovadosNoLote: 1,
      serial: serial,
      operador: '01 — Ana',
    );

    final report = await db.getTraceabilityBySerial(serial);
    expect(report, isNotNull);
    expect(report!.attempts, hasLength(2));
    expect(report.product?.nome, 'Sirene X');
    expect(report.latestApproved?.veredito, 'APROVADO');
    expect(report.canReprint, isTrue);
    expect(isApprovedVeredito(report.finalVeredito), isTrue);
  });

  test('searchSerialPrefixes retorna seriais distintos limitados', () async {
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-1',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 1,
      aprovadosNoLote: 1,
      serial: '12326000011',
    );
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-1',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 2,
      aprovadosNoLote: 2,
      serial: '12326000012',
    );
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-2',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 1,
      aprovadosNoLote: 1,
      serial: '99926000001',
    );

    final matches = await db.searchSerialPrefixes('12326');
    expect(matches, ['12326000011', '12326000012']);
    expect(await db.searchSerialPrefixes(''), isEmpty);
  });

  test('batchReportSummaries agrupa por OP com datas', () async {
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-A',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 1,
      aprovadosNoLote: 1,
      serial: '12326000011',
    );
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-B',
      veredito: 'REPROVADO',
      potenciaMedia: 15,
      sequencial: 1,
      aprovadosNoLote: 0,
    );

    final batches = await db.batchReportSummaries();
    expect(batches, hasLength(2));
    expect(batches.any((b) => b.numeroOp == 'OP-A' && b.aprovados == 1), isTrue);
    expect(batches.any((b) => b.numeroOp == 'OP-B' && b.reprovados == 1), isTrue);
  });

  test('testsForOp filtra por veredito', () async {
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-X',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 1,
      aprovadosNoLote: 1,
    );
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-X',
      veredito: 'REPROVADO',
      potenciaMedia: 15,
      sequencial: 2,
      aprovadosNoLote: 0,
    );

    final approved = await db.testsForOp('OP-X', approvedOnly: true);
    expect(approved, hasLength(1));
    expect(approved.single.veredito, 'APROVADO');
  });
}
