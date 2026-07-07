import 'package:flutter/material.dart';

import '../../features/dashboard/dashboard_filters.dart';

enum ReportExportFormat {
  pdf,
  xml;

  String get extension => name;

  String get label => switch (this) {
        ReportExportFormat.pdf => 'PDF',
        ReportExportFormat.xml => 'XML',
      };

  IconData get icon => switch (this) {
        ReportExportFormat.pdf => Icons.picture_as_pdf_outlined,
        ReportExportFormat.xml => Icons.code_outlined,
      };
}

Future<({ReportExportFormat format, bool openPrint})?> pickReportExportOptions(
  BuildContext context,
) async {
  return showDialog<({ReportExportFormat format, bool openPrint})>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Exportar relatório'),
      content: const Text('Escolha o formato do arquivo:'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, (format: ReportExportFormat.pdf, openPrint: false)),
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('PDF (só salvar)'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, (format: ReportExportFormat.pdf, openPrint: true)),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('PDF e imprimir'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, (format: ReportExportFormat.xml, openPrint: false)),
          icon: const Icon(Icons.code_outlined, size: 18),
          label: const Text('XML'),
        ),
      ],
    ),
  );
}

Future<ReportExportFormat?> pickReportExportFormat(BuildContext context) async {
  final picked = await pickReportExportOptions(context);
  return picked?.format;
}

String dashboardPeriodLabel(DashboardPeriod period) {
  return switch (period) {
    DashboardPeriod.today => 'Hoje',
    DashboardPeriod.week => 'Últimos 7 dias',
    DashboardPeriod.all => 'Todo o período',
  };
}
