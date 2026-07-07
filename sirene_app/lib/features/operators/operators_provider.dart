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

/// Sessão do operador só em memória — exige PIN a cada abertura do app.
final sessionOperatorIdProvider = StateProvider<int?>((ref) => null);

final activeOperatorProvider = FutureProvider<Operator?>((ref) async {
  final id = ref.watch(sessionOperatorIdProvider);
  if (id == null) return null;
  final op = await ref.watch(databaseProvider).getOperatorById(id);
  if (op == null || !op.ativo) return null;
  return op;
});

Future<void> setActiveOperator(WidgetRef ref, int? operatorId) async {
  ref.read(sessionOperatorIdProvider.notifier).state = operatorId;
  ref.invalidate(activeOperatorProvider);
}

Future<void> clearOperatorSession(WidgetRef ref) async {
  ref.read(sessionOperatorIdProvider.notifier).state = null;
  await ref.read(appConfigProvider).clearActiveOperatorId();
  ref.invalidate(activeOperatorProvider);
}

/// Sempre inicia sem operador logado (PIN obrigatório a cada abertura).
Future<void> clearOperatorSessionOnStartup(WidgetRef ref) async {
  await clearOperatorSession(ref);
}

/// @deprecated Use [clearOperatorSessionOnStartup]
Future<void> restoreOperatorSessionOnStartup(WidgetRef ref) =>
    clearOperatorSessionOnStartup(ref);

/// Rótulo para test_results: operador local ou fallback Firebase.
Future<String?> resolveOperadorLabel(Ref ref) async {
  final active = await ref.read(activeOperatorProvider.future);
  if (active != null) {
    return AppDatabase.operatorLabel(active);
  }
  return ref.read(authServiceProvider)?.currentUser?.email;
}

Future<String?> resolveOperatorCodigo(Ref ref) async {
  final active = await ref.read(activeOperatorProvider.future);
  return active?.codigo;
}

Future<int?> resolveOperatorId(Ref ref) async {
  final active = await ref.read(activeOperatorProvider.future);
  return active?.id;
}

/// Gestor vê o Painel analítico; operadores comuns não.
final activeOperatorIsGestorProvider = Provider<bool>((ref) {
  final op = ref.watch(activeOperatorProvider).valueOrNull;
  return op?.isGestor ?? false;
});
