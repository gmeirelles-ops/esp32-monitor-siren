import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../mqtt/models/mqtt_messages.dart';
import 'ensaio_config.dart';
import 'ensaio_session.dart';

export 'ensaio_config.dart';
export 'ensaio_controller.dart';
export 'ensaio_session.dart';

final ensaioConfigProvider = StateProvider<EnsaioConfig>((ref) => EnsaioConfig.defaults);

final ensaioSessionProvider = StateProvider<EnsaioSession?>((ref) => null);

final ensaioRemoteStatusProvider =
    StateProvider<({String deviceId, EnsaioStatusMessage msg})?>((ref) => null);

final ensaioHistoryProvider = StreamProvider<List<EnsaioRecord>>((ref) {
  return ref.watch(databaseProvider).watchEnsaioRecords();
});

final ensaioPdfSavedProvider = StateProvider<String?>((ref) => null);
