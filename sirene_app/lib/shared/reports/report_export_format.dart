import 'package:flutter/material.dart';

import '../../features/dashboard/dashboard_filters.dart';

enum ReportExportFormat {
  pdf,
  xml,
  csvSummary,
  csvTests;

  String get extension => switch (this) {
        ReportExportFormat.pdf => 'pdf',
        ReportExportFormat.xml => 'xml',
        ReportExportFormat.csvSummary || ReportExportFormat.csvTests => 'csv',
      };

  String get label => switch (this) {
        ReportExportFormat.pdf => 'PDF',
        ReportExportFormat.xml => 'XML',
        ReportExportFormat.csvSummary => 'CSV resumo',
        ReportExportFormat.csvTests => 'CSV testes',
      };

  IconData get icon => switch (this) {
        ReportExportFormat.pdf => Icons.picture_as_pdf_outlined,
        ReportExportFormat.xml => Icons.code_outlined,
        ReportExportFormat.csvSummary || ReportExportFormat.csvTests =>
          Icons.table_chart_outlined,
      };

  bool get isCsv =>
      this == ReportExportFormat.csvSummary || this == ReportExportFormat.csvTests;
}

Future<({ReportExportFormat format, bool openPrint})?> pickReportExportOptions(
  BuildContext context, {
  bool includeCsv = false,
  bool csvSummary = true,
  bool csvTests = true,
}) async {
  final showCsvSummary = includeCsv && csvSummary;
  final showCsvTests = includeCsv && csvTests;
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
        if (showCsvSummary)
          FilledButton.icon(
            onPressed: () =>
                Navigator.pop(ctx, (format: ReportExportFormat.csvSummary, openPrint: false)),
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text('CSV resumo'),
          ),
        if (showCsvTests)
          FilledButton.icon(
            onPressed: () =>
                Navigator.pop(ctx, (format: ReportExportFormat.csvTests, openPrint: false)),
            icon: const Icon(Icons.list_alt_outlined, size: 18),
            label: const Text('CSV testes'),
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
