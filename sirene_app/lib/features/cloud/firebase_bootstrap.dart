import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_log.dart';
import '../../firebase_options.dart';

bool firebaseInitialized = false;

/// Estado Riverpod do init Firebase (o bool global sozinho nao invalida providers).
final firebaseReadyProvider = StateProvider<bool>((ref) => false);

/// Firebase Flutter SDK ships native plugins for Windows/macOS/mobile only.
bool get _isFirebaseNativePlatformSupported {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS =>
      true,
    _ => false,
  };
}

bool get isFirebaseAvailable {
  if (!_isFirebaseNativePlatformSupported) return false;
  try {
    return DefaultFirebaseOptions.currentPlatform.apiKey.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Mensagem para Configurações quando sync em nuvem não está disponível.
String get firebaseUnavailableMessage {
  if (!_isFirebaseNativePlatformSupported) {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'No Linux o sync Firestore não está disponível (SDK Firebase '
          'sem plugin nativo). Use o build Windows no posto para nuvem. '
          'MQTT, lotes, etiquetas e SQLite funcionam normalmente aqui.';
    }
    return 'Firebase não disponível nesta plataforma.';
  }
  if (!isFirebaseAvailable) {
    return 'Firebase não configurado neste build. Operação local disponível.';
  }
  return '';
}

void _markFirebaseReady() {
  firebaseInitialized = true;
}

void publishFirebaseReady(WidgetRef ref) {
  if (firebaseInitialized) {
    ref.read(firebaseReadyProvider.notifier).state = true;
  }
}

/// Inicializa Firebase sob demanda (não no `main`) para evitar crash nativo no arranque.
Future<bool> ensureFirebaseInitialized() async {
  if (firebaseInitialized) return true;
  if (!isFirebaseAvailable) {
    await AppLog.write('Firebase: não disponível neste build');
    return false;
  }

  try {
    await AppLog.write('Firebase: initializeApp...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AppLog.write('Firebase: initializeApp ok');

    final persistence = defaultTargetPlatform != TargetPlatform.windows;
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: persistence,
    );
    await AppLog.write('Firebase: Firestore settings ok (persist=$persistence)');

    _markFirebaseReady();
    return true;
  } catch (e, st) {
    debugPrint('Firebase initialization failed: $e\n$st');
    await AppLog.write('Firebase: falhou', error: e, stack: st);
    return false;
  }
}

/// Inicializa Firebase e publica o estado para os providers Riverpod.
Future<bool> ensureFirebaseReady(WidgetRef ref) async {
  final ok = await ensureFirebaseInitialized();
  if (ok) {
    publishFirebaseReady(ref);
  }
  return ok;
}

@Deprecated('Use ensureFirebaseInitialized')
Future<bool> initializeFirebase() => ensureFirebaseInitialized();
