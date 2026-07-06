import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../shared/display_labels.dart';
import '../../shared/reports/report_export_format.dart';
import '../../shared/reports/report_xml_utils.dart';
import '../../features/dashboard/dashboard_filters.dart';
import '../../features/dashboard/dashboard_providers.dart';
import '../../features/traceability/report_filters.dart';

final _xmlDateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

String formatBatchListXml(
  List<BatchReportSummary> batches, {
  ReportFilters? filters,
}) {
  final body = StringBuffer()
    ..writeln('  <meta>')
    ..writeln('    ${xmlElement('titulo', text: 'Lista de lotes')}')
    ..writeln('    ${xmlElement('periodo', text: filters != null ? dashboardPeriodLabel(filters.period) : null)}')
    ..writeln('  </meta>')
    ..writeln('  <lotes>');
  for (final b in batches) {
    body.writeln(
      '    ${xmlElement('lote', attrs: {
        'numeroOp': b.numeroOp,
        'total': b.total,
        'aprovados': b.aprovados,
        'reprovados': b.reprovados,
        'rendimentoPct': b.yieldPct.toStringAsFixed(1),
        'inicio': b.firstTestAt != null ? _xmlDateFmt.format(b.firstTestAt!.toLocal()) : null,
        'fim': b.lastTestAt != null ? _xmlDateFmt.format(b.lastTestAt!.toLocal()) : null,
      })}',
    );
  }
  body.writeln('  </lotes>');
  return xmlDocument('relatorioLotes', body.toString());
}

String formatBatchDetailXml(
  String numeroOp,
  List<TestResult> tests, {
  Map<String, Product>? productsById,
  Map<String, int>? bancadaNumeros,
}) {
  final numeros = bancadaNumeros ?? const {};
  final body = StringBuffer()
    ..writeln('  <meta>')
    ..writeln('    ${xmlElement('titulo', text: 'Detalhe do lote')}')
    ..writeln('    ${xmlElement('numeroOp', text: numeroOp)}')
    ..writeln('    ${xmlElement('total', text: '${tests.length}')}')
    ..writeln('  </meta>')
    ..writeln('  <testes>');
  for (final t in tests) {
    body.writeln(
      '    ${xmlElement('teste', attrs: {
        'serial': t.serial,
        'sequencial': t.sequencial,
        'produto': formatProductLabelFromSerial(t.serial, catalog: productsById),
        'veredito': t.veredito,
        'potenciaDb': t.potenciaMedia.toStringAsFixed(1),
        'tempoSec': t.tempoTesteSec,
        'potenciaMinDb': t.potenciaMin?.toStringAsFixed(1),
        'potenciaMaxDb': t.potenciaMax?.toStringAsFixed(1),
        'bancada': formatBancadaLabelFromMap(t.deviceId, numeros),
        'operador': t.operador,
        'data': _xmlDateFmt.format(t.createdAt.toLocal()),
      })}',
    );
  }
  body.writeln('  </testes>');
  return xmlDocument('relatorioLote', body.toString());
}

String formatDashboardXml({
  required DashboardData data,
  required DashboardFilters filters,
  String? stationId,
  String? operatorLabel,
}) {
  final body = StringBuffer()
    ..writeln('  <meta>')
    ..writeln('    ${xmlElement('titulo', text: 'Painel de produção')}')
    ..writeln('    ${xmlElement('periodo', text: dashboardPeriodLabel(filters.period))}')
    ..writeln('    ${xmlElement('posto', text: stationId)}')
    ..writeln('    ${xmlElement('operador', text: operatorLabel)}')
    ..writeln('  </meta>')
    ..writeln('  <resumo>')
    ..writeln('    ${xmlElement('testado', text: '${data.summary.total}')}')
    ..writeln('    ${xmlElement('aprovados', text: '${data.summary.aprovados}')}')
    ..writeln('    ${xmlElement('reprovados', text: '${data.summary.reprovados}')}')
    ..writeln('    ${xmlElement('rendimentoPct', text: data.summary.yieldPct.toStringAsFixed(1))}')
    ..writeln('  </resumo>')
    ..writeln('  <throughputDiario>');
  for (final d in data.throughput) {
    body.writeln(
      '    ${xmlElement('dia', attrs: {
        'data': DateFormat('yyyy-MM-dd').format(d.day),
        'testado': d.total,
        'aprovados': d.aprovados,
      })}',
    );
  }
  body.writeln('  </throughputDiario>');
  if (data.faults.isNotEmpty) {
    body.writeln('  <falhasHardware>');
    for (final f in data.faults) {
      body.writeln('    ${xmlElement('falha', attrs: {'nome': f.falha, 'quantidade': f.count})}');
    }
    body.writeln('  </falhasHardware>');
  }
  if (data.batchSummaries.isNotEmpty) {
    body.writeln('  <lotes>');
    for (final b in data.batchSummaries) {
      body.writeln(
        '    ${xmlElement('lote', attrs: {
          'numeroOp': b.numeroOp,
          'total': b.total,
          'aprovados': b.aprovados,
          'reprovados': b.reprovados,
          'rendimentoPct': b.yieldPct.toStringAsFixed(1),
        })}',
      );
    }
    body.writeln('  </lotes>');
  }
  return xmlDocument('relatorioPainel', body.toString());
}
