import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_bootstrap.dart';
import 'auth_service.dart';

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
