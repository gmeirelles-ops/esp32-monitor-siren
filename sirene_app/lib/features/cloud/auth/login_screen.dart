import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_log.dart';
import '../firebase_bootstrap.dart';
import '../sync/sync_providers.dart';
import 'auth_providers.dart';
import 'auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isFirebaseAvailable) {
      setState(() => _error = 'Firebase não configurado neste build.');
      return;
    }

    final ok = await ensureFirebaseReady(ref);
    if (!ok) {
      setState(() => _error = 'Não foi possível iniciar o Firebase neste PC.');
      return;
    }

    final service = ref.read(authServiceProvider);
    if (service == null) {
      setState(() => _error = 'Serviço de autenticação indisponível. Tente novamente.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppLog.write('Login nuvem: tentando signIn');
      await service.signIn(_email.text, _password.text);
      ref.invalidate(authStateProvider);
      ref.invalidate(firestoreSyncServiceProvider);
      ref.invalidate(syncQueueProcessorProvider);
      await AppLog.write('Login nuvem: signIn ok');
      if (ref.read(syncEnabledProvider)) {
        ensureSyncProcessorRunning(ref);
        unawaited(ref.read(syncQueueProcessorProvider).processQueue());
      }
      widget.onSuccess?.call();
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      await AppLog.write('Login nuvem: FirebaseAuthException ${e.code}');
      setState(() => _error = AuthService.messageForCode(e.code));
    } catch (e, st) {
      await AppLog.write('Login nuvem: erro inesperado', error: e, stack: st);
      setState(() => _error = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login — Nuvem')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Entre com a conta de operador para habilitar a sincronização Firestore.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                      if (!v.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a senha';
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
