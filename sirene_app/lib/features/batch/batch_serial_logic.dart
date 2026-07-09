import '../../core/database/database.dart';
import '../mqtt/models/mqtt_messages.dart';

/// Ano de lote (2 dígitos) derivado da data local do posto.
String resolveBatchYear([DateTime? now]) {
  final y = (now ?? DateTime.now()).year % 100;
  return y.toString().padLeft(2, '0');
}

/// Próximo sequencial para um **novo** cadastro de lote (006 FR-006).
///
/// Não usa histórico global — firmware zera contadores; serial de produção
/// começa no inicial do produto ou em 1.
int resolveNewBatchSequencial({int? sequencialInicial}) {
  if (sequencialInicial == null || sequencialInicial < 1) {
    return 1;
  }
  return sequencialInicial;
}

/// Próximo sequencial para `SET_BATCH`, a partir do contador local e do
/// [sequencialInicial] do produto (quando os seriais não começam em 0001).
///
/// O firmware, ao receber `SET_BATCH`, aplica o sequencial do payload
/// com reset de contadores (006) — ver `batch_cmd.c` em sirene-validator.
Future<int> resolveProximoSequencial(
  AppDatabase db,
  String idProduto,
  String ano, {
  int? sequencialInicial,
}) async {
  final last = await db.getLastSequencial(idProduto, ano);
  final counterNext = (last ?? 0) + 1;
  if (sequencialInicial == null || sequencialInicial < 1) {
    return counterNext;
  }
  return counterNext > sequencialInicial ? counterNext : sequencialInicial;
}

/// Próximo sequencial a atribuir em uma aprovação, alinhado ao firmware.
///
/// Com [aprovadosJaNoLote] usa a fórmula inicial + aprovados (útil antes de
/// [activeBatch.proximoSequencial] ser atualizado). Sem o parâmetro, usa o
/// contador corrente do lote (após atualizações pós-emissão).
int nextBatchSequencial(BatchConfig batch, {int? aprovadosJaNoLote}) {
  if (aprovadosJaNoLote != null) {
    return batch.proximoSequencial + aprovadosJaNoLote;
  }
  return batch.proximoSequencial;
}
