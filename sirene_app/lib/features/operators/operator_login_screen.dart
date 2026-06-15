import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import 'operator_form_screen.dart';
import 'operators_provider.dart';

class OperatorLoginScreen extends ConsumerStatefulWidget {
  const OperatorLoginScreen({super.key});

  @override
  ConsumerState<OperatorLoginScreen> createState() => _OperatorLoginScreenState();
}

class _OperatorLoginScreenState extends ConsumerState<OperatorLoginScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Operator? _selected;
  bool _loading = false;
  String? _error;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  Timer? _lockTimer;

  static const _maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);

  @override
  void dispose() {
    _pinController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  bool get _isLocked {
    if (_lockedUntil == null) return false;
    return DateTime.now().isBefore(_lockedUntil!);
  }

  int? get _lockSecondsRemaining {
    if (!_isLocked || _lockedUntil == null) return null;
    return _lockedUntil!.difference(DateTime.now()).inSeconds.clamp(0, 30);
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_isLocked) {
        _lockTimer?.cancel();
        setState(() {
          _lockedUntil = null;
          _failedAttempts = 0;
        });
      } else {
        setState(() {});
      }
    });
  }

  void _selectOperator(Operator op) {
    setState(() {
      _selected = op;
      _error = null;
      _failedAttempts = 0;
      _lockedUntil = null;
      _pinController.clear();
    });
  }

  Future<void> _submit() async {
    if (_isLocked) return;
    if (_selected == null) {
      setState(() => _error = 'Selecione um operador na lista.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final pin = _pinController.text.trim();
    if (pin != _selected!.codigo) {
      final attempts = _failedAttempts + 1;
      if (attempts >= _maxAttempts) {
        setState(() {
          _failedAttempts = attempts;
          _lockedUntil = DateTime.now().add(_lockDuration);
          _error = 'Muitas tentativas. Aguarde ${_lockDuration.inSeconds}s.';
          _loading = false;
        });
        _startLockTimer();
      } else {
        setState(() {
          _failedAttempts = attempts;
          _error = 'PIN incorreto. Tentativa $attempts de $_maxAttempts.';
          _loading = false;
        });
      }
      return;
    }

    await setActiveOperator(ref, _selected!.id);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openFirstOperatorForm() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const OperatorFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final operatorsAsync = ref.watch(activeOperatorsStreamProvider);
    final remaining = _lockSecondsRemaining;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: operatorsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Erro ao carregar operadores: $e'),
              data: (operators) {
                if (operators.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge_outlined, size: 64, color: DipontoColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum operador cadastrado',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cadastre pelo menos um operador ativo para iniciar o posto.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openFirstOperatorForm,
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Cadastrar primeiro operador'),
                      ),
                    ],
                  );
                }

                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Login do operador',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecione seu nome e informe o PIN.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          itemCount: operators.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final op = operators[index];
                            final selected = _selected?.id == op.id;
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: selected
                                      ? DipontoColors.primary
                                      : Colors.white24,
                                ),
                              ),
                              selected: selected,
                              leading: CircleAvatar(
                                backgroundColor: DipontoColors.primary.withValues(alpha: 0.2),
                                child: Text(
                                  op.nome.isNotEmpty ? op.nome[0].toUpperCase() : '?',
                                  style: const TextStyle(color: DipontoColors.primary),
                                ),
                              ),
                              title: Text(op.nome),
                              subtitle: Text('PIN: ••••', style: TextStyle(color: Colors.grey.shade500)),
                              onTap: () => _selectOperator(op),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinController,
                        decoration: const InputDecoration(
                          labelText: 'PIN',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        enabled: !_isLocked && _selected != null,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (_selected == null) return null;
                          if (v == null || v.isEmpty) return 'Informe o PIN';
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      ],
                      if (remaining != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Bloqueado por $remaining s',
                          style: const TextStyle(color: Colors.orangeAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: (_loading || _isLocked || _selected == null) ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Entrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
