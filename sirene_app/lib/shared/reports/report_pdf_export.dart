import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/database/database.dart';
import '../../shared/display_labels.dart';
import '../../shared/reports/report_export_format.dart';
import '../../shared/reports/report_file_save.dart';
import '../../features/dashboard/dashboard_filters.dart';
import '../../features/dashboard/dashboard_providers.dart';
import '../../features/traceability/report_filters.dart';

final _pdfDateFmt = DateFormat('dd/MM/yyyy HH:mm');
final _pdfDayFmt = DateFormat('dd/MM/yyyy');

final _dipontoAmber = PdfColor.fromInt(0xFFFFB300);
final _dipontoDark = PdfColor.fromInt(0xFF1E1E1E);
final _zebraLight = PdfColors.grey100;

class ReportPdfMeta {
  const ReportPdfMeta({
    this.title,
    this.subtitle,
    this.stationId,
    this.operatorLabel,
    this.periodLabel,
    this.extraLines = const [],
  });

  final String? title;
  final String? subtitle;
  final String? stationId;
  final String? operatorLabel;
  final String? periodLabel;
  final List<String> extraLines;
}

Future<String> exportReportPdf({
  required String basename,
  required Future<Uint8List> Function() build,
  bool openPrintDialog = true,
}) async {
  final bytes = await build();
  final path = await saveReportBytes(basename, bytes, 'pdf');
  if (openPrintDialog) {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
  return path;
}

Future<String> exportReportFile({
  required ReportExportFormat format,
  required String basename,
  required Future<Uint8List> Function() buildPdf,
  required String Function() buildXml,
  bool openPrintDialog = true,
}) {
  return switch (format) {
    ReportExportFormat.pdf => exportReportPdf(
        basename: basename,
        build: buildPdf,
        openPrintDialog: openPrintDialog,
      ),
    ReportExportFormat.xml => Future.value(
        saveReportText(basename, buildXml(), 'xml'),
      ),
    ReportExportFormat.csvSummary || ReportExportFormat.csvTests =>
      throw UnsupportedError(
        'CSV deve ser exportado pelo fluxo do Painel (file_selector).',
      ),
  };
}

Future<Uint8List> buildBatchListPdf(
  List<BatchReportSummary> batches, {
  ReportFilters? filters,
  ReportPdfMeta? meta,
}) {
  return _buildDocument(
    meta: meta ?? const ReportPdfMeta(title: 'Lista de lotes'),
    columns: const ['OP', 'Total', 'Aprov.', 'Reprov.', 'Rend.%', 'Início', 'Fim'],
    rows: [
      for (final b in batches)
        [
          b.numeroOp,
          '${b.total}',
          '${b.aprovados}',
          '${b.reprovados}',
          '${b.yieldPct.toStringAsFixed(1)}%',
          b.firstTestAt != null ? _pdfDateFmt.format(b.firstTestAt!.toLocal()) : '-',
          b.lastTestAt != null ? _pdfDateFmt.format(b.lastTestAt!.toLocal()) : '-',
        ],
    ],
    periodLabel: filters != null ? dashboardPeriodLabel(filters.period) : null,
  );
}

Future<Uint8List> buildBatchDetailPdf(
  String numeroOp,
  List<TestResult> tests, {
  Map<String, Product>? productsById,
  Map<String, int>? bancadaNumeros,
  ReportPdfMeta? meta,
}) {
  final numeros = bancadaNumeros ?? const {};
  return _buildDocument(
    meta: meta ??
        ReportPdfMeta(
          title: 'Detalhe do lote',
          subtitle: 'OP $numeroOp',
          extraLines: ['${tests.length} testes'],
        ),
    columns: const ['Serial', 'Veredito', 'Pot.dB', 'Bancada', 'Operador', 'Data'],
    rows: [
      for (final t in tests)
        [
          t.serial ?? 'Seq. ${t.sequencial}',
          t.veredito,
          t.potenciaMedia.toStringAsFixed(1),
          formatBancadaLabelFromMap(t.deviceId, numeros),
          t.operador ?? '-',
          _pdfDateFmt.format(t.createdAt.toLocal()),
        ],
    ],
  );
}

Future<Uint8List> buildDashboardPdf({
  required DashboardData data,
  required DashboardFilters filters,
  String? stationId,
  String? operatorLabel,
}) async {
  final doc = pw.Document();
  final generatedAt = _pdfDateFmt.format(DateTime.now());

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        _header(
          title: 'Painel de produção',
          periodLabel: dashboardPeriodLabel(filters.period),
          stationId: stationId,
          operatorLabel: operatorLabel,
          generatedAt: generatedAt,
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _metric('Testados', '${data.summary.total}'),
              _metric('Aprovados', '${data.summary.aprovados}'),
              _metric('Reprovados', '${data.summary.reprovados}'),
              _metric('Rendimento', '${data.summary.yieldPct.toStringAsFixed(1)}%'),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text('Throughput diário', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        _table(
          columns: const ['Dia', 'Testado', 'Aprovados'],
          rows: [
            for (final d in data.throughput)
              [
                _pdfDayFmt.format(d.day),
                '${d.total}',
                '${d.aprovados}',
              ],
          ],
        ),
        if (data.faults.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Falhas de hardware', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _table(
            columns: const ['Falha', 'Quantidade'],
            rows: [for (final f in data.faults) [f.falha, '${f.count}']],
          ),
        ],
        if (data.batchSummaries.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Produção por lote', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _table(
            columns: const ['OP', 'Total', 'Aprov.', 'Reprov.', 'Rend.%'],
            rows: [
              for (final b in data.batchSummaries)
                [
                  b.numeroOp,
                  '${b.total}',
                  '${b.aprovados}',
                  '${b.reprovados}',
                  '${b.yieldPct.toStringAsFixed(1)}%',
                ],
            ],
          ),
        ],
        if (data.operatorProductivity.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Rendimento por operador', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _table(
            columns: const ['Operador', 'Testado', 'Aprov.', 'Reprov.', 'Rend.%'],
            rows: [
              for (final op in data.operatorProductivity)
                [
                  op.label,
                  '${op.total}',
                  '${op.aprovados}',
                  '${op.reprovados}',
                  '${op.yieldPct.toStringAsFixed(1)}%',
                ],
            ],
          ),
        ],
        if (data.productProductivity.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Rendimento por produto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _table(
            columns: const ['Produto', 'Testado', 'Aprov.', 'Reprov.', 'Rend.%'],
            rows: [
              for (final prod in data.productProductivity)
                [
                  prod.label,
                  '${prod.total}',
                  '${prod.aprovados}',
                  '${prod.reprovados}',
                  '${prod.yieldPct.toStringAsFixed(1)}%',
                ],
            ],
          ),
        ],
        pw.SizedBox(height: 20),
        _footer(generatedAt),
      ],
    ),
  );

  return doc.save();
}

Future<Uint8List> _buildDocument({
  required ReportPdfMeta meta,
  required List<String> columns,
  required List<List<String>> rows,
  String? periodLabel,
}) async {
  final doc = pw.Document();
  final generatedAt = _pdfDateFmt.format(DateTime.now());

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        _header(
          title: meta.title ?? 'Relatório',
          subtitle: meta.subtitle,
          periodLabel: periodLabel ?? meta.periodLabel,
          stationId: meta.stationId,
          operatorLabel: meta.operatorLabel,
          generatedAt: generatedAt,
          extraLines: meta.extraLines,
        ),
        pw.SizedBox(height: 12),
        _table(columns: columns, rows: rows),
        pw.SizedBox(height: 16),
        _footer(generatedAt),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header({
  required String title,
  String? subtitle,
  String? periodLabel,
  String? stationId,
  String? operatorLabel,
  required String generatedAt,
  List<String> extraLines = const [],
}) {
  final metaLines = <String>[
    if (periodLabel != null && periodLabel.isNotEmpty) 'Período: $periodLabel',
    if (stationId != null && stationId.isNotEmpty) 'Posto: $stationId',
    if (operatorLabel != null && operatorLabel.isNotEmpty) 'Operador: $operatorLabel',
    'Gerado em: $generatedAt',
    ...extraLines,
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Container(
        color: _dipontoAmber,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Diponto — $title',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                color: _dipontoDark,
              ),
            ),
            if (subtitle != null)
              pw.Text(
                subtitle,
                style: pw.TextStyle(fontSize: 11, color: _dipontoDark),
              ),
          ],
        ),
      ),
      if (metaLines.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
          child: pw.Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final line in metaLines)
                pw.Text(line, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _footer(String generatedAt) {
  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      'Diponto Sirene Validator · $generatedAt',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
    ),
  );
}

pw.Widget _metric(String label, String value) {
  return pw.Column(
    children: [
      pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
    ],
  );
}

pw.Widget _table({
  required List<String> columns,
  required List<List<String>> rows,
}) {
  return pw.TableHelper.fromTextArray(
    headers: columns,
    data: rows,
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _dipontoDark, fontSize: 9),
    headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFD54F)),
    cellStyle: const pw.TextStyle(fontSize: 8),
    cellAlignment: pw.Alignment.centerLeft,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    oddRowDecoration: pw.BoxDecoration(color: _zebraLight),
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.3),
  );
}
