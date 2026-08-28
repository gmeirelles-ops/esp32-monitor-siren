import 'dart:math';

import '../../core/database/database.dart';
import 'demo_constants.dart';

/// Garante catálogo, operadores e histórico mínimo para explorar o app sem ESP32/Firebase.
Future<DemoSeedResult> seedDemoEnvironment(AppDatabase db) async {
  await _seedProducts(db);
  final gestorId = await _ensureOperator(
    db,
    codigo: kDemoGestorPin,
    nome: kDemoGestorName,
    isGestor: true,
  );
  final operadorId = await _ensureOperator(
    db,
    codigo: kDemoOperadorPin,
    nome: kDemoOperadorName,
  );
  await db.syncBancadaFromFirmware(kDemoDeviceId, kDemoBancadaNum);
  await _seedHistoryIfEmpty(db, operadorId: operadorId);
  return DemoSeedResult(gestorId: gestorId, operadorId: operadorId);
}

class DemoSeedResult {
  const DemoSeedResult({required this.gestorId, required this.operadorId});

  final int gestorId;
  final int operadorId;
}

Future<void> _seedProducts(AppDatabase db) async {
  final catalog = [
    (
      id: '071',
      nome: 'Sirene Modelo A',
      potenciaRef: 35.0,
      potenciaMin: 30.0,
      potenciaMax: 40.0,
    ),
    (
      id: '072',
      nome: 'Sirene Modelo B',
      potenciaRef: 30.0,
      potenciaMin: 25.0,
      potenciaMax: 35.0,
    ),
  ];

  for (final p in catalog) {
    final existing = await db.getProduct(p.id);
    if (existing != null) continue;
    await db.upsertProduct(
      idProduto: p.id,
      nome: p.nome,
      potenciaRef: p.potenciaRef,
      potenciaMin: p.potenciaMin,
      potenciaMax: p.potenciaMax,
      toleranciaPct: 5,
      tempoTesteSec: 5,
      sequencialInicial: 1,
    );
  }
}

Future<int> _ensureOperator(
  AppDatabase db, {
  required String codigo,
  required String nome,
  bool isGestor = false,
}) async {
  final all = await db.getAllOperators();
  for (final existing in all) {
    if (existing.codigo == codigo) {
      if (existing.nome != nome || existing.isGestor != isGestor || !existing.ativo) {
        await db.updateOperator(
          id: existing.id,
          codigo: codigo,
          nome: nome,
          ativo: true,
          isGestor: isGestor,
        );
      }
      return existing.id;
    }
  }
  return db.insertOperator(codigo: codigo, nome: nome, isGestor: isGestor);
}

Future<void> _seedHistoryIfEmpty(AppDatabase db, {required int operadorId}) async {
  final existing = await db.testResultsFiltered(numeroOp: kDemoHistoryOp);
  if (existing.isNotEmpty) return;

  final rng = Random(42);
  final now = DateTime.now();
  var aprovados = 0;

  for (var i = 1; i <= 14; i++) {
    final approved = rng.nextDouble() < kDemoDefaultApprovalRate;
    if (approved) aprovados++;
    final potencia = approved
        ? 30.0 + rng.nextDouble() * 8
        : (rng.nextBool() ? 24.0 : 43.0);
    final minutesAgo = (14 - i) * 7 + rng.nextInt(5);

    await db.insertTestResult(
      deviceId: kDemoDeviceId,
      numeroOp: kDemoHistoryOp,
      veredito: approved ? 'APROVADO' : 'REPROVADO',
      potenciaMedia: potencia,
      sequencial: i,
      aprovadosNoLote: aprovados,
      serial: approved ? _demoSerial(i) : null,
      operador: kDemoOperadorName,
      operatorId: operadorId,
      tempoTesteSec: 5,
      potenciaMin: 30,
      potenciaMax: 40,
      firmwareTsMs: now.subtract(Duration(minutes: minutesAgo)).millisecondsSinceEpoch,
    );
  }
}

String _demoSerial(int sequencial) {
  // Ano 99 no histórico fictício — evita colidir com lotes demo no ano corrente (26).
  const demoHistoryYear = '99';
  final body = '071$demoHistoryYear${sequencial.toString().padLeft(4, '0')}';
  if (body.length != 9) return '0712600001';
  var sum = 0;
  for (var i = 0; i < 9; i++) {
    final digit = int.parse(body[i]);
    sum += (i.isEven ? digit * 3 : digit);
  }
  final check = (10 - (sum % 10)) % 10;
  return '$body$check';
}
