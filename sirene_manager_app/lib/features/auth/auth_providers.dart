import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_bootstrap.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  static String messageForCode(String code) {
    return switch (code) {
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'E-mail ou senha incorretos.',
      'invalid-email' => 'E-mail inválido.',
      _ => 'Não foi possível entrar. Tente novamente.',
    };
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (!firebaseInitialized) return null;
  return FirebaseAuth.instance;
});

final authServiceProvider = Provider<AuthService?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) return null;
  return AuthService(auth);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  if (service == null) return Stream.value(null);
  return service.authStateChanges;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});
