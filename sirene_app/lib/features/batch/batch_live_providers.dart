import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../dashboard/dashboard_providers.dart';
import '../../core/database/batch_metrics.dart';

export '../../core/database/batch_metrics.dart';

/// Sessão corrente usou simulador de desenvolvimento.
final batchDevSimulatorUsedProvider = StateProvider<bool>((ref) => false);

/// Modo reteste ativo no lote corrente (não consome serial nem cota).
final retestModeProvider = StateProvider<bool>((ref) => false);

/// Disparado quando o lote é encerrado automaticamente ao atingir a meta.
final autoBatchEndedProvider =
    StateProvider<({String deviceId, String numeroOp})?>((ref) => null);

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
