import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;

import '../../firebase_options.dart';

bool firebaseInitialized = false;

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

Future<bool> initializeFirebase() async {
  if (firebaseInitialized) return true;
  if (!isFirebaseAvailable) return false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    firebaseInitialized = true;
    return true;
  } catch (e, st) {
    debugPrint('Firebase initialization failed: $e\n$st');
    return false;
  }
}
