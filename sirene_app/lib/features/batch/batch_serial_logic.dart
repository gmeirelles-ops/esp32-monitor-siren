import '../../core/database/database.dart';
import '../mqtt/models/mqtt_messages.dart';

/// Ano de lote (2 dígitos) derivado da data local do posto.
String resolveBatchYear([DateTime? now]) {
  final y = (now ?? DateTime.now()).year % 100;
  return y.toString().padLeft(2, '0');
}

/// Próximo sequencial para `SET_BATCH`, a partir do contador local.
Future<int> resolveProximoSequencial(
  AppDatabase db,
  String idProduto,
  String ano,
) async {
  final last = await db.getLastSequencial(idProduto, ano);
  return (last ?? 0) + 1;
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
