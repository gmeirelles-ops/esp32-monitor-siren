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

BatchMetrics computeBatchMetrics(Iterable<TestResult> rows) {
  var aprovados = 0;
  for (final r in rows) {
    if (isApprovedVeredito(r.veredito)) aprovados++;
  }
  final total = rows.length;
  return BatchMetrics(
    total: total,
    aprovados: aprovados,
    reprovados: total - aprovados,
  );
}
