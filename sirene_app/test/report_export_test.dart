import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/dashboard/dashboard_filters.dart';
import 'package:sirene_app/features/dashboard/dashboard_providers.dart';
import 'package:sirene_app/shared/reports/report_pdf_export.dart';
import 'package:sirene_app/shared/reports/report_xml_export.dart';

void main() {
  test('formatBatchListXml contém lotes e metadados', () {
    final xml = formatBatchListXml([
      const BatchReportSummary(
        numeroOp: 'OP-100',
        total: 10,
        aprovados: 8,
        firstTestAt: null,
        lastTestAt: null,
      ),
    ]);
    expect(xml, contains('<?xml version="1.0"'));
    expect(xml, contains('<relatorioLotes'));
    expect(xml, contains('numeroOp="OP-100"'));
    expect(xml, contains('rendimentoPct="80.0"'));
  });

  test('formatBatchDetailXml contém testes', () {
    final xml = formatBatchDetailXml('OP-1', [
      TestResult(
        id: 1,
        deviceId: 'dev1',
        numeroOp: 'OP-1',
        veredito: 'APROVADO',
        potenciaMedia: 20.5,
        sequencial: 3,
        aprovadosNoLote: 1,
        serial: '12326000001',
        operador: '01 — Ana',
        isRetest: false,
        createdAt: DateTime(2026, 3, 1, 10, 30),
      ),
    ]);
    expect(xml, contains('<relatorioLote'));
    expect(xml, contains('serial="12326000001"'));
    expect(xml, contains('veredito="APROVADO"'));
  });

  test('formatDashboardXml contém resumo', () {
    final xml = formatDashboardXml(
      data: const DashboardData(
        summary: ProductionSummary(total: 5, aprovados: 4),
        throughput: [],
        faults: [],
        recentAlerts: [],
        batchSummaries: [],
        filterOptions: DashboardFilterOptions(ops: [], products: [], devices: []),
        operatorProductivity: [],
        productProductivity: [],
      ),
      filters: const DashboardFilters(period: DashboardPeriod.week),
      stationId: 'posto-1',
    );
    expect(xml, contains('<relatorioPainel'));
    expect(xml, contains('<testado>5</testado>'));
    expect(xml, contains('<posto>posto-1</posto>'));
  });

  test('buildBatchListPdf gera bytes PDF', () async {
    final bytes = await buildBatchListPdf([
      const BatchReportSummary(
        numeroOp: 'OP-1',
        total: 2,
        aprovados: 2,
        firstTestAt: null,
        lastTestAt: null,
      ),
    ]);
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
