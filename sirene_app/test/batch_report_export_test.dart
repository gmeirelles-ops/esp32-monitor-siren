import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/traceability/batch_report_export.dart';

void main() {
  test('formatBatchListCsv inclui cabeçalho e linhas', () {
    final csv = formatBatchListCsv([
      const BatchReportSummary(
        numeroOp: 'OP-100',
        total: 10,
        aprovados: 8,
        firstTestAt: null,
        lastTestAt: null,
      ),
    ]);
    expect(csv, contains('Rendimento %'));
    expect(csv, contains('OP-100;10;8;2;80.0'));
  });

  test('formatBatchDetailCsv formata testes', () {
    final catalog = <String, Product>{
      '123': const Product(
        idProduto: '123',
        nome: 'Sirene X',
        potenciaRef: 20,
        potenciaMin: 18,
        potenciaMax: 22,
        toleranciaPct: 10,
        tempoTesteSec: 5,
        calibradoEm: null,
        calibradoDeviceId: null,
      ),
    };
    final csv = formatBatchDetailCsv('OP-1', [
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
    ], productsById: catalog, bancadaNumeros: {'dev1': 5});
    expect(csv, contains('Produto'));
    expect(csv, contains('Bancada'));
    expect(csv, contains('123 — Sirene X'));
    expect(csv, contains('Bancada 5'));
  });

  test('formatBatchDetailCsv sem mapa usa placeholder', () {
    final csv = formatBatchDetailCsv('OP-1', [
      TestResult(
        id: 1,
        deviceId: 'dev1',
        numeroOp: 'OP-1',
        veredito: 'APROVADO',
        potenciaMedia: 20.5,
        sequencial: 1,
        aprovadosNoLote: 1,
        serial: null,
        operador: null,
        isRetest: false,
        createdAt: DateTime(2026, 3, 1),
      ),
    ]);
    expect(csv, contains('Bancada …'));
  });
}
