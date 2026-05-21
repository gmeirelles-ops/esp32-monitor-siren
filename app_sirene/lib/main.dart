import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'screens/live_test_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox<dynamic>(DatabaseService.boxHistoricoPendentes);

  await SyncService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.amber,
      primary: kDipontoAmber,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Sistema QA Sirenes',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        primaryColor: kDipontoAmber,
        appBarTheme: const AppBarTheme(
          backgroundColor: kDipontoAmber,
          foregroundColor: kDipontoNavy,
          iconTheme: IconThemeData(color: kDipontoNavy),
          titleTextStyle: TextStyle(
            color: kDipontoNavy,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/setup': (_) => const SetupScreen(),
      },
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/live-test') {
          final LiveTestArgs args = settings.arguments! as LiveTestArgs;
          return MaterialPageRoute<void>(
            builder: (_) => LiveTestScreen(args: args),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
