import '../database.dart';
import '../constants/sync_constants.dart';

/// Operações da fila de sync — agrupadas para facilitar testes e manutenção.
extension SyncQueueDao on AppDatabase {
  Future<int> countPendingSync() => countPending();

  Future<int> countFailedSync() => countFailed();

  int get syncMaxAttempts => syncQueueMaxAttempts;
}
