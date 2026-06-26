import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../database/database.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig(ref.watch(sharedPreferencesProvider));
});

final bancadaSetupCompleteProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).bancadaSetupComplete;
});

final wifiProvisionedProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).wifiProvisioned;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
