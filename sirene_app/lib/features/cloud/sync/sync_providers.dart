import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../auth/auth_providers.dart';
import '../firebase_bootstrap.dart';
import 'firestore_sync_service.dart';
import 'sync_queue_processor.dart';

class SyncStatus {
  const SyncStatus({
    required this.pending,
    required this.failed,
    this.lastSync,
    required this.enabled,
    required this.firebaseAvailable,
    required this.authenticated,
  });

  final int pending;
  final int failed;
  final DateTime? lastSync;
  final bool enabled;
  final bool firebaseAvailable;
  final bool authenticated;
}

final syncEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(appConfigProvider).syncEnabled;
});

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final config = ref.watch(appConfigProvider);
  return FirestoreSyncService(
    db: ref.watch(databaseProvider),
    isSyncEnabled: () => ref.read(syncEnabledProvider) && firebaseInitialized,
    stationId: () => config.stationId,
  );
});

final syncQueueProcessorProvider = Provider<SyncQueueProcessor>((ref) {
  final processor = SyncQueueProcessor(
    db: ref.watch(databaseProvider),
    syncService: ref.watch(firestoreSyncServiceProvider),
    firestore: firebaseInitialized ? FirebaseFirestore.instance : null,
  );

  ref.listen(syncEnabledProvider, (prev, next) {
    if (next) {
      processor.start();
      processor.processQueue();
    } else {
      processor.stop();
    }
  });

  ref.onDispose(processor.dispose);
  return processor;
});

final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  ref.watch(syncEnabledProvider);
  final db = ref.watch(databaseProvider);
  final processor = ref.watch(syncQueueProcessorProvider);
  final config = ref.watch(appConfigProvider);
  final authenticated = ref.watch(isAuthenticatedProvider);

  return SyncStatus(
    pending: await db.countPending(),
    failed: await db.countFailed(),
    lastSync: processor.lastSuccessfulSync,
    enabled: config.syncEnabled,
    firebaseAvailable: isFirebaseAvailable,
    authenticated: authenticated,
  );
});

Future<void> setSyncEnabled(WidgetRef ref, bool enabled) async {
  final config = ref.read(appConfigProvider);
  await config.setSyncEnabled(enabled);
  ref.read(syncEnabledProvider.notifier).state = enabled;
  if (enabled) {
    ref.read(syncQueueProcessorProvider).start();
    await ref.read(syncQueueProcessorProvider).processQueue();
  }
}
