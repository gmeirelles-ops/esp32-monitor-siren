import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../features/operators/operators_provider.dart';
import 'report_pdf_export.dart';

Future<ReportPdfMeta> loadReportPdfMeta(WidgetRef ref) async {
  final config = ref.read(appConfigProvider);
  final operator = await ref.read(activeOperatorProvider.future);
  return ReportPdfMeta(
    stationId: config.stationId.isEmpty ? null : config.stationId,
    operatorLabel: operator == null ? null : operator.nome,
  );
}

String? operatorLabel(Operator? operator) {
  if (operator == null) return null;
  return operator.nome;
}

Future<({String? stationId, String? operatorLabel})> loadReportContext(WidgetRef ref) async {
  final config = ref.read(appConfigProvider);
  final operator = await ref.read(activeOperatorProvider.future);
  final stationId = config.stationId;
  return (
    stationId: stationId.isEmpty ? null : stationId,
    operatorLabel: operatorLabel(operator),
  );
}
