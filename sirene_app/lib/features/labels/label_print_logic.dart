/// Imprime entradas em blocos de até 3 e retorna os ids efetivamente impressos.
/// Em falha parcial, retorna apenas os ids dos blocos enviados antes do erro.
Future<({List<int> printedIds, Object? error})> printLabelBatches({
  required List<({int id, String serial})> entries,
  required Future<void> Function(List<String> serials) sendZpl,
  int batchSize = 3,
}) async {
  final printedIds = <int>[];
  var index = 0;

  while (index < entries.length) {
    final end = (index + batchSize).clamp(0, entries.length);
    final batch = entries.sublist(index, end);
    try {
      await sendZpl(batch.map((e) => e.serial).toList());
      printedIds.addAll(batch.map((e) => e.id));
      index = end;
    } catch (e) {
      return (printedIds: printedIds, error: e);
    }
  }

  return (printedIds: printedIds, error: null);
}
