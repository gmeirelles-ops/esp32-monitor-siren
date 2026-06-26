import '../../core/database/database.dart';

const defaultYieldTargetPct = 70.0;

enum BatchStatus { emAndamento, concluido, revisar }

BatchStatus batchStatusFor(
  BatchProductionSummary batch, {
  double yieldTarget = defaultYieldTargetPct,
}) {
  if (batch.total == 0) return BatchStatus.emAndamento;
  if (batch.yieldPct < yieldTarget) return BatchStatus.revisar;
  final last = batch.lastTestAt;
  if (last != null && DateTime.now().difference(last) < const Duration(hours: 2)) {
    return BatchStatus.emAndamento;
  }
  return BatchStatus.concluido;
}

double? percentChange(int current, int previous) {
  if (previous == 0) return current > 0 ? 100 : null;
  return ((current - previous) / previous) * 100;
}
