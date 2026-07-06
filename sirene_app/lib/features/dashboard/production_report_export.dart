import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/database/database.dart';
import 'dashboard_filters.dart';

String formatDashboardSummaryCsv({
  required ProductionSummary summary,
  required List<DailyThroughput> throughput,
  required List<FaultCount> faults,
  required DashboardFilters filters,
}) {
  final buf = StringBuffer();
  buf.writeln('Relatório de produção — Diponto Sirene Validator');
  buf.writeln('Gerado em;${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
  buf.writeln('Período;${filters.period.name}');
  buf.writeln();
  buf.writeln('Resumo');
  buf.writeln('Métrica;Valor');
  buf.writeln('Testado;${summary.total}');
  buf.writeln('Aprovados;${summary.aprovados}');
  buf.writeln('Reprovados;${summary.reprovados}');
  buf.writeln('Rendimento %;${summary.yieldPct.toStringAsFixed(1)}');
  buf.writeln();
  buf.writeln('Throughput diário');
  buf.writeln('Dia;Testado;Aprovados');
  for (final d in throughput) {
    buf.writeln(
      '${DateFormat('yyyy-MM-dd').format(d.day)};${d.total};${d.aprovados}',
    );
  }
  if (faults.isNotEmpty) {
    buf.writeln();
    buf.writeln('Falhas de hardware');
    buf.writeln('Falha;Quantidade');
    for (final f in faults) {
      buf.writeln('${f.falha};${f.count}');
    }
  }
  return buf.toString();
}

Future<File> saveDashboardCsv(String content) async {
  final dir = await getApplicationDocumentsDirectory();
  final reportsDir = Directory(p.join(dir.path, 'relatorios'));
  if (!await reportsDir.exists()) {
    await reportsDir.create(recursive: true);
  }
  final name = 'painel_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
  final file = File(p.join(reportsDir.path, name));
  await file.writeAsString(content);
  return file;
}
