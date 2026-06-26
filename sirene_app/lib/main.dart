import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'features/cloud/firebase_bootstrap.dart';
import 'features/mqtt/mqtt_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  final prefs = await SharedPreferences.getInstance();
  await AppConfig.migrateBancadaSetupIfNeeded(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SireneApp(),
    ),
  );
}
