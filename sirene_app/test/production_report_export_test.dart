import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/dashboard/dashboard_filters.dart';
import 'package:sirene_app/features/dashboard/production_report_export.dart';

void main() {
  group('csv helpers', () {
    test('csvCell escapa ponto e vírgula e aspas', () {
      expect(csvCell('ok'), 'ok');
      expect(csvCell('a;b'), '"a;b"');
      expect(csvCell('diz "oi"'), '"diz ""oi"""');
    });

    test('csvDecimal usa vírgula', () {
      expect(csvDecimal(12.5), '12,5');
      expect(csvDecimal(100, fractionDigits: 0), '100');
    });

    test('defaultDashboardCsvFileName', () {
      final n = defaultDashboardCsvFileName(
        testsDetail: false,
        now: DateTime(2026, 8, 27, 11, 2, 3),
      );
      expect(n, 'painel_resumo_20260827_110203.csv');
      expect(
        defaultDashboardCsvFileName(
          testsDetail: true,
          now: DateTime(2026, 8, 27, 11, 2, 3),
        ),
        'painel_testes_20260827_110203.csv',
      );
    });
  });

  group('formatDashboardSummaryCsv', () {
    test('inclui BOM, cabeçalhos e rendimento com vírgula', () {
      final csv = formatDashboardSummaryCsv(
        summary: const ProductionSummary(total: 10, aprovados: 7),
        throughput: [
          DailyThroughput(
            day: DateTime(2026, 8, 26),
            total: 4,
            aprovados: 3,
          ),
        ],
        faults: const [FaultCount(falha: 'pzem_timeout', count: 2)],
        filters: const DashboardFilters(
          period: DashboardPeriod.week,
          numeroOp: 'OP-1',
        ),
        generatedAt: DateTime(2026, 8, 27, 12),
      );
      expect(csv.startsWith(kCsvUtf8Bom), isTrue);
      expect(csv, contains('Período;Últimos 7 dias'));
      expect(csv, contains('OP;OP-1'));
      expect(csv, contains('Testado;10'));
      expect(csv, contains('Rendimento %;70,0'));
      expect(csv, contains('2026-08-26;4;3'));
      expect(csv, contains('pzem_timeout;2'));
    });

    test('sem BOM quando withBom=false', () {
      final csv = formatDashboardSummaryCsv(
        summary: const ProductionSummary(total: 0, aprovados: 0),
        throughput: const [],
        faults: const [],
        filters: const DashboardFilters(),
        withBom: false,
      );
      expect(csv.startsWith(kCsvUtf8Bom), isFalse);
      expect(csv.startsWith('Relatório'), isTrue);
    });
  });

  group('formatDashboardTestsCsv', () {
    test('lista testes com BOM e decimal PT', () {
      final csv = formatDashboardTestsCsv(
        [
          TestResult(
            id: 1,
            deviceId: 'dev-a',
            numeroOp: 'OP9',
            veredito: 'APROVADO',
            potenciaMedia: 85.5,
            sequencial: 1,
            aprovadosNoLote: 1,
            serial: '1232600012',
            operador: 'Ana',
            tempoTesteSec: 5,
            potenciaMin: 80,
            potenciaMax: 90,
            operatorId: null,
            isRetest: false,
            firmwareTsMs: null,
            createdAt: DateTime(2026, 8, 27, 10, 0),
          ),
        ],
        bancadaNumeros: {'dev-a': 3},
      );
      expect(csv.startsWith(kCsvUtf8Bom), isTrue);
      expect(csv, contains('OP;Serial;Produto'));
      expect(csv, contains('OP9'));
      expect(csv, contains('85,5'));
      expect(csv, contains('Ana'));
    });
  });
}
