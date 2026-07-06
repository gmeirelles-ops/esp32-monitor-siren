import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/database/database.dart';
import '../../shared/display_labels.dart';
import 'ensaio_controller.dart';

final _pdfDateFmt = DateFormat('dd/MM/yyyy HH:mm');

final _dipontoAmber = PdfColor.fromInt(0xFFFFB300);
final _dipontoDark = PdfColor.fromInt(0xFF1E1E1E);

class EnsaioPdfContext {
  const EnsaioPdfContext({
    required this.record,
    required this.bancadaLabel,
    this.stationId,
  });

  final EnsaioRecord record;
  final String bancadaLabel;
  final String? stationId;
}

String ensaioStatusLabel(String status) {
  return switch (status) {
    'running' => 'Em andamento',
    'concluido' => 'Concluído',
    'interrompido' => 'Interrompido',
    'falha' => 'Falha',
    _ => status,
  };
}

String ensaioMotivoLabel(String? motivo) {
  return switch (motivo) {
    'duracao' => 'Duração total atingida',
    'parado' => 'Parado manualmente (app ou botão)',
    null => '-',
    _ => motivo!,
  };
}

String sanitizeEnsaioBasename(String nome) {
  final cleaned = nome
      .trim()
      .replaceAll(RegExp(r'[^\w\s\-]+', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), '_');
  if (cleaned.isEmpty) return 'ensaio';
  return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
}

Future<Uint8List> buildEnsaioPdf(EnsaioPdfContext ctx) {
  final r = ctx.record;
  final doc = pw.Document();
  final generatedAt = _pdfDateFmt.format(DateTime.now());
  final endedAt = r.endedAt ?? DateTime.now();

  final rows = <List<String>>[
    ['Nome do ensaio', r.nome],
    ['Bancada', ctx.bancadaLabel],
    if (ctx.stationId != null && ctx.stationId!.isNotEmpty) ['Posto', ctx.stationId!],
    if (r.operador != null && r.operador!.isNotEmpty) ['Operador', r.operador!],
    ['Início', _pdfDateFmt.format(r.startedAt.toLocal())],
    ['Fim', _pdfDateFmt.format(endedAt.toLocal())],
    ['Tempo ligado', '${r.onSeconds ~/ 60} min'],
    ['Tempo desligado', '${r.offSeconds ~/ 60} min'],
    ['Duração programada', formatEnsaioDuration(r.totalSeconds)],
    ['Tempo executado', formatEnsaioDuration(r.elapsedSec)],
    ['Ciclos completos', '${r.ciclos}'],
    ['Resultado', ensaioStatusLabel(r.status)],
    ['Motivo', ensaioMotivoLabel(r.motivo)],
    if (r.demoMode) ['Modo', 'Demonstração (simulado)'],
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Container(
          color: _dipontoAmber,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Diponto — Relatório de ensaio',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  color: _dipontoDark,
                ),
              ),
              pw.Text(
                r.nome,
                style: pw.TextStyle(fontSize: 11, color: _dipontoDark),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            pw.Text('Gerado em: $generatedAt', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('ID registro: ${r.id}', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Parâmetros e resultado',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Campo', 'Valor'],
          data: rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _dipontoDark, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFD54F)),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
          },
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.3),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'O ensaio alterna energização da sirene (ligado/desligado) conforme tempos '
          'configurados, para teste de resistência ou validação operacional.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Diponto Sirene Validator · $generatedAt',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

String ensaioBancadaLabel(EnsaioRecord record, Map<String, int> bancadas) {
  return formatBancadaLabelFromMap(record.deviceId, bancadas);
}
