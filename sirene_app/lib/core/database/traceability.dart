import 'database.dart';
import 'veredito.dart';

/// Dados agregados de rastreabilidade de uma sirene por serial.
class SirenTraceability {
  const SirenTraceability({
    required this.serial,
    required this.attempts,
    this.product,
    this.pendingMark,
  });

  final String serial;
  final List<TestResult> attempts;
  final Product? product;
  final MarkQueueEntry? pendingMark;

  TestResult? get latestAttempt =>
      attempts.isNotEmpty ? attempts.last : null;

  TestResult? get latestApproved {
    for (var i = attempts.length - 1; i >= 0; i--) {
      if (isApprovedVeredito(attempts[i].veredito)) return attempts[i];
    }
    return null;
  }

  bool get canReprint => latestApproved != null;

  /// Alias laser de [canReprint].
  bool get canRemark => canReprint;

  String get finalVeredito => latestAttempt?.veredito ?? '—';

  String get markingStatus {
    if (pendingMark != null) return 'Na fila de gravação';
    if (latestApproved != null) return 'Serial gerado';
    return 'Sem serial';
  }

  DateTime? get markGeneratedAt {
    if (pendingMark != null) return pendingMark!.createdAt;
    return latestApproved?.createdAt;
  }
}
