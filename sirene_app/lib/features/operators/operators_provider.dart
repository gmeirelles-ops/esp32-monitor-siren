import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../cloud/auth/auth_providers.dart';
import '../mqtt/mqtt_providers.dart';

final operatorsStreamProvider = StreamProvider<List<Operator>>((ref) {
  return ref.watch(databaseProvider).watchAllOperators();
});

final activeOperatorsStreamProvider = StreamProvider<List<Operator>>((ref) {
  return ref.watch(databaseProvider).watchActiveOperators();
});

final activeOperatorProvider = FutureProvider<Operator?>((ref) async {
  final config = ref.watch(appConfigProvider);
  final id = config.activeOperatorId;
  if (id == null) return null;
  final op = await ref.watch(databaseProvider).getOperatorById(id);
  if (op == null || !op.ativo) return null;
  return op;
});

Future<void> setActiveOperator(WidgetRef ref, int? operatorId) async {
  await ref.read(appConfigProvider).setActiveOperatorId(operatorId);
  ref.invalidate(activeOperatorProvider);
}

Future<void> clearOperatorSession(WidgetRef ref) async {
  await setActiveOperator(ref, null);
}

/// Rótulo para test_results: operador local ou fallback Firebase.
Future<String?> resolveOperadorLabel(Ref ref) async {
  final active = await ref.read(activeOperatorProvider.future);
  if (active != null) {
    return AppDatabase.operatorLabel(active);
  }
  return ref.read(authServiceProvider)?.currentUser?.email;
}
