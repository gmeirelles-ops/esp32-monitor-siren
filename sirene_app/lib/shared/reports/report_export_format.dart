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

Future<ReportExportFormat?> pickReportExportFormat(BuildContext context) {
  return showDialog<ReportExportFormat>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Exportar relatório'),
      content: const Text('Escolha o formato do arquivo:'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        for (final format in ReportExportFormat.values)
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, format),
            icon: Icon(format.icon, size: 18),
            label: Text(format.label),
          ),
      ],
    ),
  );
}

String dashboardPeriodLabel(DashboardPeriod period) {
  return switch (period) {
    DashboardPeriod.today => 'Hoje',
    DashboardPeriod.week => 'Últimos 7 dias',
    DashboardPeriod.all => 'Todo o período',
  };
}
