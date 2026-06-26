import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import 'laser_tcp_diagnostics.dart';
import 'mark_queue_processor.dart';

final markQueueProcessorProvider = Provider<MarkQueueProcessor>((ref) {
  final db = ref.watch(databaseProvider);
  final processor = MarkQueueProcessor(
    db: db,
    readConfig: () => ref.read(appConfigProvider),
  );
  ref.onDispose(processor.stop);
  return processor;
});

final laserTcpEventLogProvider = Provider<LaserTcpEventLog>((ref) {
  return ref.watch(markQueueProcessorProvider).eventLog;
});

final markFailureProvider = StateProvider<String?>((ref) => null);

final pendingMarkCountProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseProvider).watchPendingMarkQueueCount();
});
