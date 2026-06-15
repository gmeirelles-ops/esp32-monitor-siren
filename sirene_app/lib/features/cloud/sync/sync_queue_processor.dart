import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/database/database.dart';
import 'firestore_sync_service.dart';

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
  } else {
    await doc.set(converted);
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
    this.maxAttempts = 5,
    this.interval = const Duration(seconds: 30),
  })  : _db = db,
        _syncService = syncService,
        _firestore = firestore,
        _writer = writer;

  final AppDatabase _db;
  final FirestoreSyncService _syncService;
  final FirebaseFirestore? _firestore;
  final FirestoreWriter? _writer;
  final int maxAttempts;
  final Duration interval;

  Timer? _timer;
  DateTime? lastSuccessfulSync;
  bool _processing = false;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => processQueue());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> processQueue() async {
    if (_processing || !_syncService.isActive) return;
    if (_firestore == null && _writer == null) return;

    _processing = true;
    try {
      await _syncService.flushPendingDeviceUpdates();
      final items = await _db.getPendingItems();
      for (final item in items) {
        if (item.attempts >= maxAttempts) continue;
        try {
          final data = jsonDecode(item.payload) as Map<String, dynamic>;
          final path = item.documentPath;
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
          lastSuccessfulSync = DateTime.now();
        } catch (e) {
          final attempts = item.attempts + 1;
          await _db.markFailed(item.id, e.toString(), attempts: attempts);
          if (attempts < maxAttempts) {
            await Future<void>.delayed(Duration(seconds: 1 << attempts.clamp(0, 4)));
          }
        }
      }
    } finally {
      _processing = false;
    }
  }

  void dispose() => stop();
}
