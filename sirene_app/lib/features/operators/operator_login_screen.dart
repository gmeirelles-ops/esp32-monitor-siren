import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/section_intro.dart';
import 'operator_form_screen.dart';
import 'operators_provider.dart';

class OperatorLoginScreen extends ConsumerStatefulWidget {
  const OperatorLoginScreen({super.key});

  @override
  ConsumerState<OperatorLoginScreen> createState() => _OperatorLoginScreenState();
}

class _OperatorLoginScreenState extends ConsumerState<OperatorLoginScreen> {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
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
    _pinFocus.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isLocked) _pinFocus.requestFocus();
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF161616),
              DipontoColors.surface,
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: operatorsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Erro ao carregar operadores: $e'),
                  data: (operators) {
                    if (operators.isEmpty) {
                      return _LoginPanel(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 56,
                              color: DipontoColors.primary.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Nenhum operador cadastrado',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cadastre pelo menos um operador ativo para iniciar o posto.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DipontoColors.onSurface.withValues(alpha: 0.65),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _openFirstOperatorForm,
                                icon: const Icon(Icons.person_add_outlined),
                                label: const Text('Cadastrar primeiro operador'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Form(
                      key: _formKey,
                      child: _LoginPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionIntro(
                              icon: Icons.badge_outlined,
                              title: 'Login do operador',
                              subtitle: 'Selecione seu nome e informe o PIN para iniciar o turno.',
                            ),
                            Text(
                              'Operadores',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: DipontoColors.onSurface.withValues(alpha: 0.7),
                                    letterSpacing: 0.4,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: DipontoColors.surfaceVariant.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: DipontoColors.onSurface.withValues(alpha: 0.08),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < operators.length; i++) ...[
                                      if (i > 0)
                                        Divider(
                                          height: 1,
                                          color: DipontoColors.onSurface.withValues(alpha: 0.06),
                                        ),
                                      _OperatorRow(
                                        operator: operators[i],
                                        selected: _selected?.id == operators[i].id,
                                        onTap: () => _selectOperator(operators[i]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _selected == null
                                  ? Padding(
                                      key: const ValueKey('hint'),
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Text(
                                        'Toque no seu nome para continuar.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: DipontoColors.onSurface.withValues(alpha: 0.45),
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : Column(
                                      key: ValueKey(_selected!.id),
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 20),
                                        TextFormField(
                                          controller: _pinController,
                                          focusNode: _pinFocus,
                                          decoration: InputDecoration(
                                            labelText: 'PIN de ${_displayName(_selected!)}',
                                            prefixIcon: const Icon(Icons.lock_outline),
                                            suffixIcon: _pinController.text.isNotEmpty
                                                ? IconButton(
                                                    tooltip: 'Limpar',
                                                    onPressed: () {
                                                      _pinController.clear();
                                                      setState(() {});
                                                    },
                                                    icon: const Icon(Icons.close, size: 18),
                                                  )
                                                : null,
                                          ),
                                          obscureText: true,
                                          enabled: !_isLocked,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          onChanged: (_) => setState(() {}),
                                          onFieldSubmitted: (_) => _submit(),
                                          validator: (v) {
                                            if (_selected == null) return null;
                                            if (v == null || v.isEmpty) return 'Informe o PIN';
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: DipontoColors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: DipontoColors.error.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, size: 18, color: DipontoColors.error),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(color: DipontoColors.error, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (remaining != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Bloqueado por $remaining s',
                                style: const TextStyle(color: DipontoColors.primaryLight),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: (_loading || _isLocked || _selected == null) ? null : _submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: DipontoColors.onPrimary,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _displayName(Operator op) {
    final n = op.nome.trim();
    if (n.isEmpty) return op.codigo;
    return n[0].toUpperCase() + n.substring(1);
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DipontoColors.cardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DipontoColors.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: child,
      ),
    );
  }
}

class _OperatorRow extends StatelessWidget {
  const _OperatorRow({
    required this.operator,
    required this.selected,
    required this.onTap,
  });

  final Operator operator;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _OperatorLoginScreenState._displayName(operator);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Material(
      color: selected
          ? DipontoColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? DipontoColors.primary : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? DipontoColors.primary.withValues(alpha: 0.25)
                    : DipontoColors.surfaceVariant,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: selected ? DipontoColors.primary : DipontoColors.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? DipontoColors.primary : DipontoColors.onSurface,
                      ),
                    ),
                    if (operator.isGestor && !selected)
                      Text(
                        'Gestor do posto',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DipontoColors.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                  ],
                ),
              ),
              if (operator.isGestor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DipontoColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Gestor',
                    style: TextStyle(fontSize: 11, color: DipontoColors.primaryLight),
                  ),
                ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle, color: DipontoColors.primary, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
