import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../dashboard/dashboard_providers.dart';
import '../../core/database/batch_metrics.dart';

export '../../core/database/batch_metrics.dart';

/// Sessão corrente usou simulador de desenvolvimento.
final batchDevSimulatorUsedProvider = StateProvider<bool>((ref) => false);

final batchLiveTestsProvider = StreamProvider.family<List<TestResult>, String>((ref, numeroOp) {
  ref.watch(localDataRevisionProvider);
  return ref.watch(databaseProvider).watchTestsByOp(numeroOp);
});

final batchLiveMetricsProvider = FutureProvider.family<BatchMetrics, String>((ref, numeroOp) async {
  ref.watch(localDataRevisionProvider);
  return ref.watch(databaseProvider).getBatchMetrics(numeroOp);
});

final labelBufferCountProvider = StreamProvider<int>((ref) {
  ref.watch(localDataRevisionProvider);
  return ref.watch(databaseProvider).watchLabelBufferCount();
});
