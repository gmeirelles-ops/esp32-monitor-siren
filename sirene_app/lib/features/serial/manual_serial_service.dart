import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../batch/batch_serial_logic.dart';
import '../labels/marking_providers.dart';
import '../serial/itf_check_digit.dart';

/// Resultado da emissão manual de um serial para gravação/etiqueta.
class ManualSerialIssue {
  const ManualSerialIssue({
    required this.serial,
    required this.sequencial,
    required this.idProduto,
    required this.ano,
    required this.numeroOp,
    required this.modelo,
  });

  final String serial;
  final int sequencial;
  final String idProduto;
  final String ano;
  final String numeroOp;
  final String modelo;
}

/// Próximo sequencial e serial completo (preview, sem gravar contador).
Future<({int sequencial, String serial})> previewManualSerial(
  AppDatabase db, {
  required String idProduto,
  int? sequencialInicial,
}) async {
  final ano = resolveBatchYear();
  final sequencial = await resolveProximoSequencial(
    db,
    idProduto,
    ano,
    sequencialInicial: sequencialInicial,
  );
  final serial = generateFullSerial(
    idProduto: idProduto,
    ano: ano,
    sequencial: sequencial,
  );
  return (sequencial: sequencial, serial: serial);
}

Future<ManualSerialIssue> _issueOneManualSerial({
  required AppDatabase db,
  required Product product,
  required String serial,
  required int sequencial,
  required String ano,
  required String numeroOp,
  String? operador,
  int? operatorId,
}) async {
  final issue = ManualSerialIssue(
    serial: serial,
    sequencial: sequencial,
    idProduto: product.idProduto,
    ano: ano,
    numeroOp: numeroOp,
    modelo: product.nome.trim(),
  );

  await db.insertTestResult(
    deviceId: 'manual',
    numeroOp: issue.numeroOp,
    veredito: 'MANUAL',
    potenciaMedia: 0,
    sequencial: issue.sequencial,
    aprovadosNoLote: 0,
    serial: issue.serial,
    operador: operador,
    operatorId: operatorId,
    isRetest: false,
    firmwareTsMs: DateTime.now().millisecondsSinceEpoch,
  );

  await db.addToMarkQueue(
    serial: issue.serial,
    numeroOp: issue.numeroOp,
    pinned: true,
  );
  await db.insertRemarkLog(
    serial: issue.serial,
    numeroOp: issue.numeroOp,
    mode: 'manual_laser',
    operatorId: operatorId,
  );

  return issue;
}

/// Gera N seriais consecutivos e enfileira gravação laser.
Future<List<ManualSerialIssue>> issueManualSerialBatchCore({
  required AppDatabase db,
  required Product product,
  int quantity = 1,
  String numeroOp = 'MANUAL',
  String? operador,
  int? operatorId,
  String? firstSerialOverride,
  Future<void> Function()? onLaserEnqueued,
}) async {
  if (quantity < 1) {
    throw ArgumentError('Quantidade deve ser pelo menos 1');
  }

  late final int startSeq;
  late final String ano;

  final custom = firstSerialOverride?.trim();
  if (custom != null && custom.isNotEmpty) {
    final validationError = validateItfSerialForProduct(custom, product.idProduto);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    startSeq = parseSequencialFromSerial(custom);
    ano = parseAnoFromSerial(custom);
  } else {
    final preview = await previewManualSerial(
      db,
      idProduto: product.idProduto,
      sequencialInicial: product.sequencialInicial,
    );
    startSeq = preview.sequencial;
    ano = resolveBatchYear();
  }

  if (startSeq + quantity - 1 > 9999) {
    throw ArgumentError('Sequencial ultrapassa 9999');
  }

  final op = numeroOp.trim().isEmpty ? 'MANUAL' : numeroOp.trim();
  final issues = <ManualSerialIssue>[];

  for (var i = 0; i < quantity; i++) {
    final sequencial = startSeq + i;
    final serial = generateFullSerial(
      idProduto: product.idProduto,
      ano: ano,
      sequencial: sequencial,
    );
    if (await db.serialExists(serial)) {
      throw StateError('Serial já existe: $serial');
    }
    issues.add(
      await _issueOneManualSerial(
        db: db,
        product: product,
        serial: serial,
        sequencial: sequencial,
        ano: ano,
        numeroOp: op,
        operador: operador,
        operatorId: operatorId,
      ),
    );
  }

  await db.bumpSerialCounter(
    idProduto: product.idProduto,
    ano: ano,
    sequencial: startSeq + quantity - 1,
  );
  await onLaserEnqueued?.call();

  return issues;
}

/// Lógica principal — enfileira gravação laser (serial + modelo via TCP DiatuCAD).
Future<ManualSerialIssue> issueManualSerialCore({
  required AppDatabase db,
  required Product product,
  String numeroOp = 'MANUAL',
  String? operador,
  int? operatorId,
  String? serialOverride,
  Future<void> Function()? onLaserEnqueued,
}) async {
  final issues = await issueManualSerialBatchCore(
    db: db,
    product: product,
    quantity: 1,
    numeroOp: numeroOp,
    operador: operador,
    operatorId: operatorId,
    firstSerialOverride: serialOverride,
    onLaserEnqueued: onLaserEnqueued,
  );
  return issues.single;
}

/// Gera serial(is), atualiza contador e enfileira gravação laser.
Future<List<ManualSerialIssue>> issueManualSerialBatch({
  required WidgetRef ref,
  required Product product,
  int quantity = 1,
  String numeroOp = 'MANUAL',
  String? operador,
  int? operatorId,
  String? firstSerialOverride,
}) {
  return issueManualSerialBatchCore(
    db: ref.read(databaseProvider),
    product: product,
    quantity: quantity,
    numeroOp: numeroOp,
    operador: operador,
    operatorId: operatorId,
    firstSerialOverride: firstSerialOverride,
    onLaserEnqueued: () => ref.read(markQueueProcessorProvider).ensureRunning(),
  );
}

/// Gera serial, atualiza contador e enfileira gravação laser.
Future<ManualSerialIssue> issueManualSerial({
  required WidgetRef ref,
  required Product product,
  String numeroOp = 'MANUAL',
  String? operador,
  int? operatorId,
  String? serialOverride,
}) async {
  final issues = await issueManualSerialBatch(
    ref: ref,
    product: product,
    quantity: 1,
    numeroOp: numeroOp,
    operador: operador,
    operatorId: operatorId,
    firstSerialOverride: serialOverride,
  );
  return issues.single;
}
