import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/core_providers.dart';
import '../../products/products_provider.dart';
import '../auth/auth_providers.dart';
import '../firebase_bootstrap.dart';
import 'catalog_cloud_service.dart';
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

/// Disponível apenas quando o Firebase está inicializado nesta plataforma.
final catalogCloudServiceProvider = Provider<CatalogCloudService?>((ref) {
  if (!firebaseInitialized) return null;
  final db = ref.watch(databaseProvider);
  return CatalogCloudService(
    db: db,
    reader: () async {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      return snapshot.docs.map((d) => _normalizeFirestore(d.data())).toList();
    },
  );
});

/// Normaliza valores Firestore (Timestamp → DateTime) para o mapper puro.
Map<String, dynamic> _normalizeFirestore(Map<String, dynamic> data) {
  final result = <String, dynamic>{};
  for (final entry in data.entries) {
    final value = entry.value;
    result[entry.key] = value is Timestamp ? value.toDate() : value;
  }
  return result;
}

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

final failedSyncItemsProvider = FutureProvider<List<SyncQueueData>>((ref) async {
  ref.watch(syncStatusProvider);
  final db = ref.watch(databaseProvider);
  return db.getFailedSyncItems();
});

Future<void> retryFailedSyncItems(WidgetRef ref, {int? itemId}) async {
  final db = ref.read(databaseProvider);
  if (itemId != null) {
    await db.resetSyncAttempts(itemId);
  } else {
    await db.resetAllFailedSyncAttempts();
  }
  await ref.read(syncQueueProcessorProvider).processQueue();
  ref.invalidate(syncStatusProvider);
  ref.invalidate(failedSyncItemsProvider);
}

Future<int> syncCatalogToCloud(WidgetRef ref) async {
  final sync = ref.read(firestoreSyncServiceProvider);
  final count = await sync.syncAllProducts();
  if (count > 0) {
    await ref.read(syncQueueProcessorProvider).processQueue();
  }
  ref.invalidate(syncStatusProvider);
  return count;
}

/// Baixa o catálogo da nuvem e aplica no SQLite. Retorna quantos foram aplicados.
Future<int> pullCatalogFromCloud(WidgetRef ref) async {
  final service = ref.read(catalogCloudServiceProvider);
  if (service == null) return 0;
  final applied = await service.pull();
  if (applied > 0) {
    ref.invalidate(productsStreamProvider);
  }
  return applied;
}

Future<void> setSyncEnabled(WidgetRef ref, bool enabled) async {
  final config = ref.read(appConfigProvider);
  await config.setSyncEnabled(enabled);
  ref.read(syncEnabledProvider.notifier).state = enabled;
  if (enabled) {
    ref.read(syncQueueProcessorProvider).start();
    await syncCatalogToCloud(ref);
    await ref.read(syncQueueProcessorProvider).processQueue();
    await pullCatalogFromCloud(ref);
  }
}
