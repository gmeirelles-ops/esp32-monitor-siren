import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../shared/display_labels.dart';
import '../../shared/reports/report_export_format.dart';
import 'dashboard_filters.dart';

final _csvDateFmt = DateFormat('dd/MM/yyyy HH:mm:ss');
final _csvDayFmt = DateFormat('yyyy-MM-dd');

/// Prefixo UTF-8 BOM para Excel reconhecer acentos.
const kCsvUtf8Bom = '\uFEFF';

String csvCell(String? value) {
  final v = value ?? '';
  if (v.contains(';') || v.contains('"') || v.contains('\n') || v.contains('\r')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String csvDecimal(num value, {int fractionDigits = 1}) {
  return value.toStringAsFixed(fractionDigits).replaceAll('.', ',');
}

String formatDashboardSummaryCsv({
  required ProductionSummary summary,
  required List<DailyThroughput> throughput,
  required List<FaultCount> faults,
  required DashboardFilters filters,
  List<OperatorProductivity>? operatorProductivity,
  List<ProductProductivity>? productProductivity,
  DateTime? generatedAt,
  bool withBom = true,
}) {
  final now = generatedAt ?? DateTime.now();
  final buf = StringBuffer();
  if (withBom) buf.write(kCsvUtf8Bom);
  buf.writeln('Relatório de produção — Diponto Sirene Validator');
  buf.writeln('Gerado em;${DateFormat('yyyy-MM-dd HH:mm').format(now)}');
  buf.writeln('Período;${dashboardPeriodLabel(filters.period)}');
  if (filters.numeroOp != null && filters.numeroOp!.isNotEmpty) {
    buf.writeln('OP;${csvCell(filters.numeroOp)}');
  }
  if (filters.idProduto != null && filters.idProduto!.isNotEmpty) {
    buf.writeln('Produto;${csvCell(filters.idProduto)}');
  }
  if (filters.deviceId != null && filters.deviceId!.isNotEmpty) {
    buf.writeln('Dispositivo;${csvCell(filters.deviceId)}');
  }
  buf.writeln();
  buf.writeln('Resumo');
  buf.writeln('Métrica;Valor');
  buf.writeln('Testado;${summary.total}');
  buf.writeln('Aprovados;${summary.aprovados}');
  buf.writeln('Reprovados;${summary.reprovados}');
  buf.writeln('Rendimento %;${csvDecimal(summary.yieldPct)}');
  buf.writeln();
  buf.writeln('Throughput diário');
  buf.writeln('Dia;Testado;Aprovados');
  for (final d in throughput) {
    buf.writeln('${_csvDayFmt.format(d.day)};${d.total};${d.aprovados}');
  }
  if (faults.isNotEmpty) {
    buf.writeln();
    buf.writeln('Falhas de hardware');
    buf.writeln('Falha;Quantidade');
    for (final f in faults) {
      buf.writeln('${csvCell(f.falha)};${f.count}');
    }
  }
  if (operatorProductivity != null && operatorProductivity.isNotEmpty) {
    buf.writeln();
    buf.writeln('Rendimento por operador');
    buf.writeln('Operador;Testado;Aprovados;Reprovados;Rendimento %');
    for (final op in operatorProductivity) {
      buf.writeln([
        csvCell(op.label),
        op.total,
        op.aprovados,
        op.reprovados,
        csvDecimal(op.yieldPct),
      ].join(';'));
    }
  }
  if (productProductivity != null && productProductivity.isNotEmpty) {
    buf.writeln();
    buf.writeln('Rendimento por produto');
    buf.writeln('Produto;Testado;Aprovados;Reprovados;Rendimento %');
    for (final prod in productProductivity) {
      buf.writeln([
        csvCell(prod.label),
        prod.total,
        prod.aprovados,
        prod.reprovados,
        csvDecimal(prod.yieldPct),
      ].join(';'));
    }
  }
  return buf.toString();
}

String formatDashboardTestsCsv(
  List<TestResult> tests, {
  Map<String, Product>? productsById,
  Map<String, int>? bancadaNumeros,
  bool withBom = true,
}) {
  final numeros = bancadaNumeros ?? const {};
  final buf = StringBuffer();
  if (withBom) buf.write(kCsvUtf8Bom);
  buf.writeln(
    'OP;Serial;Produto;Veredito;Sequencial;Potencia dB;Tempo s;Pot min dB;Pot max dB;Bancada;Operador;Data',
  );
  for (final t in tests) {
    buf.writeln([
      csvCell(t.numeroOp),
      csvCell(t.serial),
      csvCell(formatProductLabelFromSerial(t.serial, catalog: productsById)),
      csvCell(t.veredito),
      t.sequencial,
      csvDecimal(t.potenciaMedia),
      t.tempoTesteSec ?? '',
      t.potenciaMin != null ? csvDecimal(t.potenciaMin!) : '',
      t.potenciaMax != null ? csvDecimal(t.potenciaMax!) : '',
      csvCell(formatBancadaLabelFromMap(t.deviceId, numeros)),
      csvCell(t.operador),
      _csvDateFmt.format(t.createdAt.toLocal()),
    ].join(';'));
  }
  return buf.toString();
}

String defaultDashboardCsvFileName({
  required bool testsDetail,
  DateTime? now,
}) {
  final stamp = DateFormat('yyyyMMdd_HHmmss').format(now ?? DateTime.now());
  final kind = testsDetail ? 'testes' : 'resumo';
  return 'painel_${kind}_$stamp.csv';
}

/// Salva CSV via diálogo do sistema; retorna caminho ou null se cancelado.
Future<String?> saveCsvWithFilePicker({
  required String suggestedName,
  required String content,
}) async {
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'CSV', extensions: ['csv']),
    ],
  );
  if (location == null) return null;
  final file = File(location.path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content, encoding: utf8, flush: true);
  return file.path;
}
