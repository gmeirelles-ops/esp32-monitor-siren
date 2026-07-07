import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_version.dart';
import '../../../core/constants/sync_constants.dart';
import '../../../core/database/database.dart';
import '../../../core/services/app_log.dart';
import '../models/firestore_mappers.dart';
import 'firestore_sync_service.dart';
import 'station_heartbeat_service.dart';

typedef FirestoreWriter = Future<void> Function(
  String collection,
  String documentId,
  Map<String, dynamic> data,
  String operation, {
  String? documentPath,
});

Future<void> writeToFirestore(
  FirebaseFirestore firestore,
  String collection,
  String documentId,
  Map<String, dynamic> data,
  String operation, {
  String? documentPath,
}) async {
  final doc = documentPath != null && documentPath.isNotEmpty
      ? firestore.doc(documentPath)
      : firestore.collection(collection).doc(documentId);
  final converted = _convertTimestamps(data);
  if (operation == 'merge') {
    await doc.set(converted, SetOptions(merge: true));
    return;
  }
  if (isReprovadaFirestorePath(documentPath)) {
    await _writeImmutableReprovada(doc, converted);
    return;
  }
  await doc.set(converted);
}

/// Regras Firestore: `reprovadas` só permite create (update/delete bloqueados).
/// Re-tentativas com `set` viram update e falham com permission-denied.
Future<void> _writeImmutableReprovada(
  DocumentReference<Map<String, dynamic>> doc,
  Map<String, dynamic> data,
) async {
  final snap = await doc.get();
  if (snap.exists) return;
  try {
    await doc.set(data);
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      final again = await doc.get();
      if (again.exists) return;
    }
    rethrow;
  }
}

Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
  final result = <String, dynamic>{};
  for (final entry in data.entries) {
    final value = entry.value;
    if (value is String && _isIsoTimestamp(value)) {
      result[entry.key] = Timestamp.fromDate(DateTime.parse(value));
    } else {
      result[entry.key] = value;
    }
  }
  return result;
}

bool _isIsoTimestamp(String value) {
  return value.length >= 20 && value.contains('T') && value.endsWith('Z');
}

class SyncQueueProcessor {
  SyncQueueProcessor({
    required AppDatabase db,
    required FirestoreSyncService syncService,
    FirebaseFirestore? firestore,
    FirestoreWriter? writer,
    StationHeartbeatService? heartbeat,
    this.maxAttempts = syncQueueMaxAttempts,
    this.interval = const Duration(minutes: 1),
    this.itemsPerBatch = 100,
    this.maxBatchesPerRun = 10,
    Future<void> Function(DateTime timestamp)? onSyncSuccess,
  })  : _db = db,
        _syncService = syncService,
        _firestore = firestore,
        _writer = writer,
        _heartbeat = heartbeat ?? StationHeartbeatService(firestore: firestore),
        _onSyncSuccess = onSyncSuccess;

  final AppDatabase _db;
  final FirestoreSyncService _syncService;
  final FirebaseFirestore? _firestore;
  final FirestoreWriter? _writer;
  final StationHeartbeatService _heartbeat;
  final Future<void> Function(DateTime timestamp)? _onSyncSuccess;
  final int maxAttempts;
  final Duration interval;
  final int itemsPerBatch;
  final int maxBatchesPerRun;

  Timer? _timer;
  DateTime? lastSuccessfulSync;
  bool _processing = false;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => processQueue());
    if (!_kickoffQueued) {
      _kickoffQueued = true;
      unawaited(processQueue());
    }
  }

  bool _kickoffQueued = false;

  void stop() {
    _timer?.cancel();
    _timer = null;
    _kickoffQueued = false;
  }

  Future<void> processQueue() async {
    if (_processing || !_syncService.isActive) return;
    if (_firestore == null && _writer == null) return;

    _processing = true;
    var syncedThisRun = false;
    try {
      await _syncService.flushPendingDeviceUpdates();
      for (var batch = 0; batch < maxBatchesPerRun; batch++) {
        final items = await _db.getPendingItems(limit: itemsPerBatch);
        if (items.isEmpty) break;
        await AppLog.write(
          'Sync: processando ${items.length} item(ns) pendente(s) (lote ${batch + 1})',
        );
        for (final item in items) {
          if (item.attempts >= maxAttempts) continue;
          try {
            final raw = jsonDecode(item.payload) as Map<String, dynamic>;
            final path = item.documentPath;
            final data = patchSyncPayloadForFirestore(
              collection: item.collection,
              payload: raw,
              stationId: _syncService.stationIdForHeartbeat(),
              documentPath: path,
            );
            if (_writer != null) {
              await _writer(
                item.collection,
                item.documentId,
                data,
                item.operation,
                documentPath: path,
              );
            } else {
              await writeToFirestore(
                _firestore!,
                item.collection,
                item.documentId,
                data,
                item.operation,
                documentPath: path,
              );
            }
            await _db.markSynced(item.id);
            syncedThisRun = true;
            lastSuccessfulSync = DateTime.now();
          } catch (e) {
            final attempts = item.attempts + 1;
            await _db.markFailed(item.id, e.toString(), attempts: attempts);
            if (attempts < maxAttempts) {
              await Future<void>.delayed(Duration(seconds: 1 << attempts.clamp(0, 4)));
            }
          }
        }
        if (items.length < itemsPerBatch) break;
      }
      if (syncedThisRun && lastSuccessfulSync != null) {
        try {
          await _onSyncSuccess?.call(lastSuccessfulSync!);
        } catch (_) {
          // Persistência do timestamp é opcional.
        }
        try {
          await _heartbeat.recordHeartbeat(
            stationId: _syncService.stationIdForHeartbeat(),
            pendingQueue: await _db.countPending(),
            failedQueue: await _db.countFailed(),
            appVersion: kAppVersion,
          );
        } catch (_) {
          // Heartbeat opcional; não interrompe a fila.
        }
      }
    } catch (e, st) {
      await AppLog.write('Sync: processQueue erro geral', error: e, stack: st);
    } finally {
      _processing = false;
    }
  }

  void dispose() => stop();
}
