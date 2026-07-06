import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_bootstrap.dart';

/// Atualiza presença do posto em `stations/{stationId}` após sync bem-sucedido.
class StationHeartbeatService {
  StationHeartbeatService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isActive => firebaseInitialized && _firestore != null;

  Future<void> recordHeartbeat({
    required String stationId,
    required int pendingQueue,
    required int failedQueue,
    String? appVersion,
  }) async {
    if (!isActive) return;
    final id = stationId.trim();
    if (id.isEmpty) return;

    await _firestore!.collection('stations').doc(id).set({
      'station_id': id,
      'last_sync_at': FieldValue.serverTimestamp(),
      'pending_queue': pendingQueue,
      'failed_queue': failedQueue,
      if (appVersion != null) 'app_version': appVersion,
    }, SetOptions(merge: true));
  }
}
