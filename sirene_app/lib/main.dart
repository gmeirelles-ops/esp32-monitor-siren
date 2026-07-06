import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/app_log.dart';
import 'features/mqtt/mqtt_providers.dart';
import 'features/mqtt/mqtt_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  PlatformDispatcher.instance.onError = (error, stack) {
    MqttService.handleGlobalAsyncError(error, stack);
    AppLog.write('Uncaught async error', error: error, stack: stack);
    return true;
  };
  await AppLog.write('App iniciando');

  final prefs = await SharedPreferences.getInstance();
  await AppLog.write('Prefs carregadas');

  await AppConfig.migrateBancadaSetupIfNeeded(prefs);
  await AppLog.write('Migrate bancada ok');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SireneApp(),
    ),
  );
  await AppLog.write('runApp executado');
}
