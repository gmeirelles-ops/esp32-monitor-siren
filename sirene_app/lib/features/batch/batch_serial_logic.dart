import '../../core/database/database.dart';
import '../mqtt/models/mqtt_messages.dart';

/// Ano de lote (2 dígitos) derivado da data local do posto.
String resolveBatchYear([DateTime? now]) {
  final y = (now ?? DateTime.now()).year % 100;
  return y.toString().padLeft(2, '0');
}

/// Próximo sequencial só a partir do [sequencialInicial] do produto (sem histórico).
///
/// Preferir [resolveProximoSequencial] no fluxo de produção — mantém manual + lote
/// na mesma sequência.
int resolveNewBatchSequencial({int? sequencialInicial}) {
  if (sequencialInicial == null || sequencialInicial < 1) {
    return 1;
  }
  return sequencialInicial;
}

/// Próximo sequencial conjunto para `SET_BATCH` e emissão manual.
///
/// Usa o máximo entre:
/// - contador local `serial_counters`
/// - maior sequencial já visto no histórico local (APROVADO + MANUAL)
/// - [sequencialInicial] do produto (quando os seriais não começam em 0001)
Future<int> resolveProximoSequencial(
  AppDatabase db,
  String idProduto,
  String ano, {
  int? sequencialInicial,
}) async {
  final lastCounter = await db.getLastSequencial(idProduto, ano) ?? 0;
  final lastHistory = await db.maxSequencialInHistory(idProduto, ano) ?? 0;
  final effectiveLast =
      lastCounter > lastHistory ? lastCounter : lastHistory;
  final counterNext = effectiveLast + 1;
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
