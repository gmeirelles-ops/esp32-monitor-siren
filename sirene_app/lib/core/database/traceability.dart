import 'database.dart';
import 'veredito.dart';

/// Dados agregados de rastreabilidade de uma sirene por serial.
class SirenTraceability {
  const SirenTraceability({
    required this.serial,
    required this.attempts,
    this.product,
    this.pendingLabel,
  });

  final String serial;
  final List<TestResult> attempts;
  final Product? product;
  final LabelBufferEntry? pendingLabel;

  TestResult? get latestAttempt =>
      attempts.isNotEmpty ? attempts.last : null;

  TestResult? get latestApproved {
    for (var i = attempts.length - 1; i >= 0; i--) {
      if (isApprovedVeredito(attempts[i].veredito)) return attempts[i];
    }
    return null;
  }

  bool get canReprint => latestApproved != null;

  String get finalVeredito => latestAttempt?.veredito ?? '—';

  String get labelStatus {
    if (pendingLabel != null) return 'Na fila de impressão';
    if (latestApproved != null) return 'Etiqueta gerada';
    return 'Sem etiqueta';
  }

  DateTime? get labelGeneratedAt {
    if (pendingLabel != null) return pendingLabel!.createdAt;
    return latestApproved?.createdAt;
  }
}
