import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web não configurado.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('Plataforma não suportada para o app gestor.');
    }
  }

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDPty7URXLaLyyvqQUSYZOXmreq-Ql__bg',
    appId: '1:539202171240:web:6d1d00134b0e2e777f66dd',
    messagingSenderId: '539202171240',
    projectId: 'monitor-sirenv2-6d201',
    authDomain: 'monitor-sirenv2-6d201.firebaseapp.com',
    databaseURL: 'https://monitor-sirenv2-6d201-default-rtdb.firebaseio.com',
    storageBucket: 'monitor-sirenv2-6d201.firebasestorage.app',
    measurementId: 'G-43Z6PPPV1R',
  );
}
