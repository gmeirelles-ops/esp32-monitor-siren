import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../database/database.dart';
import '../providers/core_providers.dart';
import '../../features/cloud/auth/auth_providers.dart';
import '../../features/operators/operators_provider.dart';

/// Apaga dados locais do posto: SQLite, prefs operacionais, bancada e Wi-Fi.
class FactoryResetService {
  FactoryResetService({
    required this.ref,
    required this.prefs,
    required this.closeDatabase,
    required this.deleteDatabaseFile,
  });

  final Ref ref;
  final SharedPreferences prefs;
  final Future<void> Function() closeDatabase;
  final Future<void> Function() deleteDatabaseFile;

  Future<void> execute({bool logoutFirebase = false}) async {
    ref.read(sessionOperatorIdProvider.notifier).state = null;

    await closeDatabase();
    await deleteDatabaseFile();

    await prefs.clear();

    if (logoutFirebase) {
      await ref.read(authServiceProvider)?.signOut();
    }

    ref.invalidate(appConfigProvider);
    ref.invalidate(bancadaSetupCompleteProvider);
    ref.invalidate(wifiProvisionedProvider);
    ref.invalidate(databaseProvider);
    ref.invalidate(activeOperatorProvider);
  }
}

Future<void> deleteLocalDatabaseFile() async {
  final file = await AppDatabase.dbFile();
  if (await file.exists()) {
    await file.delete();
  }
}

final factoryResetServiceProvider = Provider<FactoryResetService>((ref) {
  return FactoryResetService(
    ref: ref,
    prefs: ref.watch(sharedPreferencesProvider),
    closeDatabase: () async {
      final db = ref.read(databaseProvider);
      await db.close();
    },
    deleteDatabaseFile: deleteLocalDatabaseFile,
  );
});
