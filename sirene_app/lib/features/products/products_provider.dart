import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../cloud/sync/sync_providers.dart';
import '../mqtt/mqtt_providers.dart';

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchProducts();
});

final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productsStreamProvider).value ?? [];
});

Future<void> syncProductToCloud(WidgetRef ref, Product product) async {
  await ref.read(firestoreSyncServiceProvider).enqueueProduct(product);
}
