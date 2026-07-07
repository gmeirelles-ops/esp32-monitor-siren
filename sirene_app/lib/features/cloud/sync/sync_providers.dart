import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/app_log.dart';
import '../../products/products_provider.dart';
import '../auth/auth_providers.dart';
import '../firebase_bootstrap.dart';
import '../../operators/operators_provider.dart';
import 'catalog_cloud_service.dart';
import 'firestore_sync_service.dart';
import 'sync_payload_repair.dart';
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

/// Garante timer periódico ativo (sobrevive a `invalidate` do processor).
void ensureSyncProcessorRunning(WidgetRef ref) {
  if (!ref.read(syncEnabledProvider)) return;
  if (isFirebaseAvailable && !ref.read(firebaseReadyProvider)) return;
  ref.read(syncQueueProcessorProvider).start();
}

/// Dispara um ciclo imediato da fila (além do timer automático).
Future<void> kickSyncQueue(WidgetRef ref) async {
  ensureSyncProcessorRunning(ref);
  await ref.read(syncQueueProcessorProvider).processQueue();
  ref.invalidate(syncStatusProvider);
}

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final config = ref.watch(appConfigProvider);
  final firebaseReady = ref.watch(firebaseReadyProvider);
  return FirestoreSyncService(
    db: ref.watch(databaseProvider),
    isSyncEnabled: () {
      if (!ref.read(syncEnabledProvider) || !firebaseReady) return false;
      if (isFirebaseAvailable && !ref.read(isAuthenticatedProvider)) return false;
      return true;
    },
    stationId: () => config.stationId,
  );
});

final syncQueueProcessorProvider = Provider<SyncQueueProcessor>((ref) {
  final firebaseReady = ref.watch(firebaseReadyProvider);
  final syncEnabled = ref.watch(syncEnabledProvider);
  final processor = SyncQueueProcessor(
    db: ref.watch(databaseProvider),
    syncService: ref.watch(firestoreSyncServiceProvider),
    firestore: firebaseReady ? FirebaseFirestore.instance : null,
    onSyncSuccess: (timestamp) async {
      await ref.read(appConfigProvider).setLastCloudSyncAt(timestamp);
    },
  );

  ref.listen(syncEnabledProvider, (prev, next) {
    if (next) {
      processor.start();
    } else {
      processor.stop();
    }
  });

  ref.listen(firebaseReadyProvider, (prev, next) {
    if (next && ref.read(syncEnabledProvider)) {
      processor.start();
    }
  });

  if (syncEnabled && firebaseReady) {
    processor.start();
  }

  ref.onDispose(processor.dispose);
  return processor;
});

/// Atualiza contadores da fila na UI sem precisar sair da tela.
final syncStatusRefreshProvider = StreamProvider<void>((ref) {
  if (!ref.watch(syncEnabledProvider)) {
    return const Stream.empty();
  }
  return Stream.periodic(const Duration(seconds: 30));
});

/// Disponível apenas quando o Firebase está inicializado nesta plataforma.
final catalogCloudServiceProvider = Provider<CatalogCloudService?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return null;
  final db = ref.watch(databaseProvider);
  return CatalogCloudService(
    db: db,
    productReader: () async {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      return snapshot.docs.map((d) => _normalizeFirestore(d.data())).toList();
    },
    operatorReader: () async {
      final snapshot = await FirebaseFirestore.instance.collection('operators').get();
      return snapshot.docs
          .map((d) => _normalizeFirestore({...d.data(), 'codigo': d.id}))
          .toList();
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
  ref.watch(syncStatusRefreshProvider);
  final db = ref.watch(databaseProvider);
  final processor = ref.watch(syncQueueProcessorProvider);
  final config = ref.watch(appConfigProvider);
  final authenticated = ref.watch(isAuthenticatedProvider);

  return SyncStatus(
    pending: await db.countPending(),
    failed: await db.countFailed(),
    lastSync: processor.lastSuccessfulSync ?? config.lastCloudSyncAt,
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
  final stationId = ref.read(firestoreSyncServiceProvider).stationIdForHeartbeat();
  final repaired = await repairSyncQueuePayloads(db, stationId, itemId: itemId);
  if (repaired > 0) {
    await AppLog.write('Sync: corrigiu station_id em $repaired item(ns) da fila');
  }
  if (itemId != null) {
    await db.resetSyncAttempts(itemId);
  } else {
    final reset = await db.resetAllFailedSyncAttempts();
    await AppLog.write('Sync: reenfileirando $reset falha(s)');
  }
  try {
    ensureSyncProcessorRunning(ref);
    await ref.read(syncQueueProcessorProvider).processQueue();
  } catch (e, st) {
    await AppLog.write('Sync: reprocessar falhas falhou', error: e, stack: st);
    rethrow;
  }
  ref.invalidate(syncStatusProvider);
  ref.invalidate(failedSyncItemsProvider);
}

Future<int> syncCatalogToCloud(WidgetRef ref) async {
  if (isFirebaseAvailable) {
    await ensureFirebaseReady(ref);
    ref.invalidate(firestoreSyncServiceProvider);
    ref.invalidate(syncQueueProcessorProvider);
  }
  ensureSyncProcessorRunning(ref);
  final sync = ref.read(firestoreSyncServiceProvider);
  final products = await sync.syncAllProducts();
  final operators = await sync.syncAllOperators();
  final count = products + operators;
  if (count > 0) {
    await ref.read(syncQueueProcessorProvider).processQueue();
  }
  ref.invalidate(syncStatusProvider);
  return count;
}

/// Baixa produtos e operadores da nuvem. Retorna total aplicado.
Future<int> pullCatalogFromCloud(WidgetRef ref) async {
  if (isFirebaseAvailable) {
    await ensureFirebaseReady(ref);
    ref.invalidate(catalogCloudServiceProvider);
    ref.invalidate(firestoreSyncServiceProvider);
    ref.invalidate(syncQueueProcessorProvider);
  }
  ensureSyncProcessorRunning(ref);
  final service = ref.read(catalogCloudServiceProvider);
  if (service == null) return 0;
  final result = await service.pullAll();
  if (result.products > 0) {
    ref.invalidate(productsStreamProvider);
  }
  if (result.operators > 0) {
    ref.invalidate(operatorsStreamProvider);
    ref.invalidate(activeOperatorsStreamProvider);
  }
  return result.total;
}

/// Detalhe do pull para mensagens na UI.
Future<CatalogPullResult> pullCatalogDetailFromCloud(WidgetRef ref) async {
  if (isFirebaseAvailable) {
    await ensureFirebaseReady(ref);
    ref.invalidate(catalogCloudServiceProvider);
    ref.invalidate(firestoreSyncServiceProvider);
    ref.invalidate(syncQueueProcessorProvider);
  }
  ensureSyncProcessorRunning(ref);
  final service = ref.read(catalogCloudServiceProvider);
  if (service == null) {
    return const CatalogPullResult(products: 0, operators: 0);
  }
  final result = await service.pullAll();
  if (result.products > 0) {
    ref.invalidate(productsStreamProvider);
  }
  if (result.operators > 0) {
    ref.invalidate(operatorsStreamProvider);
    ref.invalidate(activeOperatorsStreamProvider);
  }
  return result;
}

Future<void> setSyncEnabled(WidgetRef ref, bool enabled) async {
  final config = ref.read(appConfigProvider);
  await config.setSyncEnabled(enabled);
  ref.read(syncEnabledProvider.notifier).state = enabled;
  if (!enabled) return;

  if (isFirebaseAvailable) {
    await ensureFirebaseReady(ref);
    ref.invalidate(firestoreSyncServiceProvider);
    ref.invalidate(syncQueueProcessorProvider);
    ref.invalidate(catalogCloudServiceProvider);
  }

  ref.read(syncQueueProcessorProvider).start();

  if (!ref.read(isAuthenticatedProvider)) {
    await AppLog.write('Sync: ativo sem login Firebase (fila local apenas)');
    return;
  }

  try {
    await AppLog.write('Sync: baixando catálogo da nuvem');
    await pullCatalogFromCloud(ref);
  } catch (e, st) {
    await AppLog.write('Sync: pull catálogo falhou', error: e, stack: st);
  }

  try {
    await AppLog.write('Sync: processando fila após habilitar');
    ensureSyncProcessorRunning(ref);
    await ref.read(syncQueueProcessorProvider).processQueue();
  } catch (e, st) {
    await AppLog.write('Sync: processQueue após habilitar falhou', error: e, stack: st);
  }
}
