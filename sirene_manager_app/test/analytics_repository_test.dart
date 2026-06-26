import 'package:flutter_test/flutter_test.dart';

import 'package:sirene_manager_app/features/analytics/analytics_models.dart';
import 'package:sirene_manager_app/features/analytics/firestore_analytics_repository.dart';

void main() {
  final repo = FirestoreAnalyticsRepository();

  test('computeKpis and batchRows', () {
    final now = DateTime(2026, 6, 17, 10);
    final records = [
      AnalyticsTestRecord(
        numeroOp: '212312',
        idProduto: '123',
        stationId: 'posto-01',
        deviceId: 'aa',
        veredito: 'APROVADO',
        timestamp: now,
      ),
      AnalyticsTestRecord(
        numeroOp: '212312',
        idProduto: '123',
        stationId: 'posto-01',
        deviceId: 'aa',
        veredito: 'REPROVADO',
        timestamp: now.add(const Duration(minutes: 5)),
      ),
      AnalyticsTestRecord(
        numeroOp: '999',
        idProduto: '123',
        stationId: 'posto-02',
        deviceId: 'bb',
        veredito: 'APROVADO',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
    ];

    final kpis = repo.computeKpis(records);
    expect(kpis.total, 3);
    expect(kpis.aprovados, 2);
    expect(kpis.reprovados, 1);

    final rows = repo.batchRows(records);
    expect(rows.length, 2);
    expect(rows.first.numeroOp, '212312');
    expect(rows.first.status, BatchStatus.revisar);
  });

  test('throughputByDay buckets', () {
    final day = DateTime(2026, 6, 17, 12);
    final records = [
      AnalyticsTestRecord(
        numeroOp: '1',
        idProduto: '123',
        stationId: 'p',
        deviceId: 'd',
        veredito: 'APROVADO',
        timestamp: day,
      ),
    ];
    final throughput = repo.throughputByDay(records, 7);
    expect(throughput.length, 7);
    expect(throughput.last.aprovados, 1);
  });
}
