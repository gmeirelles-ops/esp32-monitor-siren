import 'dart:convert';

import '../../../core/database/database.dart';
import '../models/firestore_mappers.dart';

/// Corrige payloads na fila local sem `station_id` (falhas permission-denied).
Future<int> repairSyncQueuePayloads(
  AppDatabase db,
  String stationId, {
  int? itemId,
}) async {
  final id = stationId.trim();
  if (id.isEmpty) return 0;

  final items = itemId != null
      ? [
          await db.getSyncQueueItem(itemId),
        ].whereType<SyncQueueData>()
      : await db.getAllSyncQueueItems();

  var repaired = 0;
  for (final item in items) {
    final data = jsonDecode(item.payload) as Map<String, dynamic>;
    final patched = patchSyncPayloadForFirestore(
      collection: item.collection,
      payload: data,
      stationId: id,
      documentPath: item.documentPath,
    );
    if (mapEquals(data, patched)) continue;
    await db.updateSyncQueuePayload(item.id, jsonEncode(patched));
    repaired++;
  }
  return repaired;
}

bool mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
