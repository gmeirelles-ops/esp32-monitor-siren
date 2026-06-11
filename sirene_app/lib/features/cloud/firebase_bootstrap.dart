import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

bool firebaseInitialized = false;

Future<bool> initializeFirebase() async {
  if (firebaseInitialized) return true;
  if (!DefaultFirebaseOptions.isConfigured) return false;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  firebaseInitialized = true;
  return true;
}

bool get isFirebaseAvailable => DefaultFirebaseOptions.isConfigured;
