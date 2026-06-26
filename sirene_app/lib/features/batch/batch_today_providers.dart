import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../dashboard/dashboard_providers.dart';

/// Resumo de testes do dia corrente (posto local).
final batchTodaySummaryProvider = FutureProvider<ProductionSummary>((ref) async {
  ref.watch(localDataRevisionProvider);
  final now = DateTime.now();
  final since = DateTime(now.year, now.month, now.day);
  return ref.watch(databaseProvider).productionSummary(since: since);
});
