import '../../core/database/database.dart';

class LabelBufferOpGroup {
  const LabelBufferOpGroup({
    required this.numeroOp,
    required this.entries,
  });

  final String numeroOp;
  final List<LabelBufferEntry> entries;

  int get count => entries.length;
  int get orphanCount => count % 3;
  DateTime get oldestCreatedAt => entries.first.createdAt;
}

/// Agrupa etiquetas pendentes por OP, ordenando lotes pela entrada mais antiga.
List<LabelBufferOpGroup> groupLabelBufferByOp(List<LabelBufferEntry> entries) {
  final byOp = <String, List<LabelBufferEntry>>{};
  for (final entry in entries) {
    final op = entry.numeroOp.trim().isEmpty ? 'Sem OP' : entry.numeroOp;
    byOp.putIfAbsent(op, () => []).add(entry);
  }

  final groups = <LabelBufferOpGroup>[];
  for (final entry in byOp.entries) {
    final sorted = [...entry.value]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    groups.add(LabelBufferOpGroup(numeroOp: entry.key, entries: sorted));
  }
  groups.sort((a, b) => a.oldestCreatedAt.compareTo(b.oldestCreatedAt));
  return groups;
}
