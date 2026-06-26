import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'analytics_models.dart';
import 'firestore_analytics_repository.dart';

final analyticsRepositoryProvider = Provider<FirestoreAnalyticsRepository>(
  (ref) => FirestoreAnalyticsRepository(),
);

final analyticsFiltersProvider = StateProvider<AnalyticsFilters>(
  (ref) => const AnalyticsFilters(),
);

final analyticsDashboardProvider = FutureProvider<AnalyticsDashboardData>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    throw StateError('Não autenticado');
  }
  // Garante token no Firestore antes da query (evita permission-denied transitório).
  await user.getIdToken();

  final filters = ref.watch(analyticsFiltersProvider);
  return ref.watch(analyticsRepositoryProvider).loadDashboard(filters);
});
