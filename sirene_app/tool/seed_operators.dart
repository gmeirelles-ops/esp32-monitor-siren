// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../lib/firebase_options.dart';

Future<void> main(List<String> args) async {
  const email = String.fromEnvironment(
    'FIREBASE_EMAIL',
    defaultValue: 'operador.teste@diponto.com.br',
  );
  const password = String.fromEnvironment(
    'FIREBASE_PASSWORD',
    defaultValue: 'SireneTeste2026!',
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        await auth.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        rethrow;
      }
    }
  }

  final now = DateTime.now().toUtc();
  final operators = [
    (codigo: '1001', nome: 'Sheila', isGestor: false),
    (codigo: '1002', nome: 'Cleiton', isGestor: false),
    (codigo: '1003', nome: 'Andre', isGestor: true),
  ];

  final firestore = FirebaseFirestore.instance;
  for (final op in operators) {
    await firestore.collection('operators').doc(op.codigo).set({
      'codigo': op.codigo,
      'nome': op.nome,
      'ativo': true,
      'is_gestor': op.isGestor,
      'updated_at': now,
    });
    print('OK: PIN ${op.codigo} — ${op.nome}${op.isGestor ? ' (gestor)' : ''}');
  }

  final snapshot = await firestore.collection('operators').get();
  print('\nOperadores na nuvem (${snapshot.docs.length}):');
  for (final doc in snapshot.docs) {
    final data = doc.data();
    print('  ${data['codigo']} — ${data['nome']} (gestor=${data['is_gestor']})');
  }
}
