import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/dashboard/dashboard_batch_status.dart';

void main() {
  test('batchStatusFor marca revisar abaixo da meta', () {
    const batch = BatchProductionSummary(
      numeroOp: 'OP-1',
      total: 10,
      aprovados: 6,
      lastTestAt: null,
    );
    expect(batchStatusFor(batch), BatchStatus.revisar);
  });

  test('batchStatusFor marca em andamento se teste recente', () {
    final batch = BatchProductionSummary(
      numeroOp: 'OP-2',
      total: 10,
      aprovados: 9,
      lastTestAt: DateTime.now(),
    );
    expect(batchStatusFor(batch), BatchStatus.emAndamento);
  });

  test('batchStatusFor marca concluído com rendimento ok e sem atividade recente', () {
    final batch = BatchProductionSummary(
      numeroOp: 'OP-3',
      total: 10,
      aprovados: 9,
      lastTestAt: DateTime.now().subtract(const Duration(hours: 3)),
    );
    expect(batchStatusFor(batch), BatchStatus.concluido);
  });
}
