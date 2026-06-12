import '../mqtt/models/mqtt_messages.dart';

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
