import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;

import '../firebase_options.dart';

bool firebaseInitialized = false;

bool get isFirebaseAvailable {
  if (kIsWeb) return false;
  final supported = switch (defaultTargetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS =>
      true,
    _ => false,
  };
  if (!supported) return false;
  try {
    return DefaultFirebaseOptions.currentPlatform.apiKey.isNotEmpty;
  } catch (_) {
    return false;
  }
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
