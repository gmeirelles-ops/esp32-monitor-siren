import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/database/database.dart';
import '../../core/database/veredito.dart';
import '../../shared/display_labels.dart';

final _csvDateFmt = DateFormat('dd/MM/yyyy HH:mm:ss');
final _fileDateFmt = DateFormat('yyyyMMdd_HHmmss');

String _csvCell(String? value) {
  final v = value ?? '';
  if (v.contains(';') || v.contains('"') || v.contains('\n')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

/// CSV resumo de lotes filtrados.
String formatBatchListCsv(List<BatchReportSummary> batches) {
  final buf = StringBuffer()
    ..writeln('OP;Total;Aprovados;Reprovados;Rendimento %;Inicio;Fim');
  for (final b in batches) {
    buf.writeln([
      _csvCell(b.numeroOp),
      b.total,
      b.aprovados,
      b.reprovados,
      b.yieldPct.toStringAsFixed(1),
      b.firstTestAt != null ? _csvDateFmt.format(b.firstTestAt!.toLocal()) : '',
      b.lastTestAt != null ? _csvDateFmt.format(b.lastTestAt!.toLocal()) : '',
    ].join(';'));
  }
  return buf.toString();
}

/// CSV detalhado de sirenes testadas em um lote.
String formatBatchDetailCsv(
  String numeroOp,
  List<TestResult> tests, {
  Map<String, Product>? productsById,
  Map<String, int>? bancadaNumeros,
}) {
  final numeros = bancadaNumeros ?? const {};
  final buf = StringBuffer()
    ..writeln('OP;Serial;Produto;Veredito;Sequencial;Potencia dB;Tempo s;Pot min dB;Pot max dB;Bancada;Operador;Data');
  for (final t in tests) {
    buf.writeln([
      _csvCell(numeroOp),
      _csvCell(t.serial),
      _csvCell(formatProductLabelFromSerial(t.serial, catalog: productsById)),
      _csvCell(t.veredito),
      t.sequencial,
      t.potenciaMedia.toStringAsFixed(1),
      t.tempoTesteSec ?? '',
      t.potenciaMin?.toStringAsFixed(1) ?? '',
      t.potenciaMax?.toStringAsFixed(1) ?? '',
      _csvCell(formatBancadaLabelFromMap(t.deviceId, numeros)),
      _csvCell(t.operador),
      _csvDateFmt.format(t.createdAt.toLocal()),
    ].join(';'));
  }
  return buf.toString();
}

/// Salva CSV em Documents/relatorios e retorna o caminho absoluto.
Future<String> saveReportCsv(String basename, String content) async {
  final dir = await getApplicationDocumentsDirectory();
  final reportsDir = Directory(p.join(dir.path, 'relatorios'));
  if (!await reportsDir.exists()) {
    await reportsDir.create(recursive: true);
  }
  final stamp = _fileDateFmt.format(DateTime.now());
  final file = File(p.join(reportsDir.path, '${basename}_$stamp.csv'));
  await file.writeAsString(content, encoding: utf8);
  return file.path;
}

List<TestResult> filterTestsByVeredito(
  List<TestResult> tests, {
  required bool? approvedOnly,
}) {
  if (approvedOnly == null) return tests;
  return tests
      .where((t) => approvedOnly ? isApprovedVeredito(t.veredito) : !isApprovedVeredito(t.veredito))
      .toList();
}
