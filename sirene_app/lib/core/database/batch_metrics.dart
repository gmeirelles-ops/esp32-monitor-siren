import 'database.dart';
import 'veredito.dart';

/// Métricas agregadas de testes de uma OP.
class BatchMetrics {
  const BatchMetrics({
    required this.total,
    required this.aprovados,
    required this.reprovados,
  });

  final int total;
  final int aprovados;
  final int reprovados;

  double get yieldPct => total == 0 ? 0 : (aprovados / total) * 100;

  int pendentes(int quantidadeTotal) {
    if (quantidadeTotal <= 0) return 0;
    return (quantidadeTotal - aprovados).clamp(0, quantidadeTotal);
  }
}

/// Contagem ao vivo na bancada (heartbeat ou último teste MQTT).
int? resolveFirmwareAprovados({int? heartbeat, int? lastTest}) {
  final candidates = <int>[
    if (heartbeat != null) heartbeat,
    if (lastTest != null) lastTest,
  ];
  if (candidates.isEmpty) return null;
  return candidates.reduce((a, b) => a > b ? a : b);
}

BatchMetrics computeSessionBatchMetrics(
  Iterable<TestResult> rows, {
  DateTime? since,
}) {
  final filtered = since != null
      ? rows.where((r) => !r.createdAt.isBefore(since))
      : rows;
  return computeBatchMetrics(filtered);
}

/// Usa contador do firmware quando o SQLite ainda não recebeu todos os `tipo:teste`.
BatchMetrics mergeFirmwareAprovados(BatchMetrics metrics, int? firmwareAprovados) {
  if (firmwareAprovados == null || firmwareAprovados <= metrics.aprovados) {
    return metrics;
  }
  final missingApproved = firmwareAprovados - metrics.aprovados;
  return BatchMetrics(
    total: metrics.total + missingApproved,
    aprovados: firmwareAprovados,
    reprovados: metrics.reprovados,
  );
}

BatchMetrics computeBatchMetrics(Iterable<TestResult> rows) {
  final production = rows.where((r) => !r.isRetest);
  var aprovados = 0;
  for (final r in production) {
    if (isApprovedVeredito(r.veredito)) aprovados++;
  }
  final total = production.length;
  return BatchMetrics(
    total: total,
    aprovados: aprovados,
    reprovados: total - aprovados,
  );
}
