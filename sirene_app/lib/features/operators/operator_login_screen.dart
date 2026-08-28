import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/diponto_brand_mark.dart';
import '../demo/demo_constants.dart';
import '../demo/demo_service.dart';
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
  bool _enteringDemo = false;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isLocked) _pinFocus.requestFocus();
      });
    });
  }

  Future<void> _submit() async {
    if (_isLocked) return;
    if (_selected == null) {
      setState(() => _error = 'Toque no seu nome na lista.');
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

  Future<void> _enterDemoMode() async {
    setState(() {
      _enteringDemo = true;
      _error = null;
    });
    try {
      await enterDemoModeFromLogin(ref, asGestor: true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Não foi possível iniciar a demonstração: $e');
      }
    } finally {
      if (mounted) setState(() => _enteringDemo = false);
    }
  }

  List<Operator> _sortedOperators(List<Operator> operators) {
    final copy = List<Operator>.from(operators);
    copy.sort((a, b) {
      if (a.isGestor != b.isGestor) return a.isGestor ? 1 : -1;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return copy;
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
              Color(0xFF141414),
              Color(0xFF0A0A0A),
              Color(0xFF050505),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: operatorsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Erro ao carregar operadores: $e'),
                  data: (operators) {
                    if (operators.isEmpty) {
                      return _LoginShell(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _LoginHeader(),
                            const SizedBox(height: 32),
                            Icon(
                              Icons.group_add_outlined,
                              size: 48,
                              color: DipontoColors.primary.withValues(alpha: 0.75),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum operador cadastrado',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cadastre quem trabalha no posto para iniciar o turno.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DipontoColors.onSurface.withValues(alpha: 0.6),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _openFirstOperatorForm,
                                icon: const Icon(Icons.person_add_outlined),
                                label: const Text('Cadastrar operador'),
                              ),
                            ),
                            _DemoFooter(
                              enteringDemo: _enteringDemo,
                              loading: _loading,
                              locked: _isLocked,
                              onDemo: _enterDemoMode,
                            ),
                          ],
                        ),
                      );
                    }

                    final sorted = _sortedOperators(operators);
                    final floorOps = sorted.where((o) => !o.isGestor).toList();
                    final gestores = sorted.where((o) => o.isGestor).toList();

                    return Form(
                      key: _formKey,
                      child: _LoginShell(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _LoginHeader(),
                            const SizedBox(height: 28),
                            Text(
                              'Quem está no posto?',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Toque no seu nome e digite o PIN.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DipontoColors.onSurface.withValues(alpha: 0.62),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (floorOps.isNotEmpty) ...[
                              _SectionLabel(title: 'Operadores'),
                              const SizedBox(height: 10),
                              _OperatorGrid(
                                operators: floorOps,
                                selectedId: _selected?.id,
                                onSelect: _selectOperator,
                              ),
                            ],
                            if (gestores.isNotEmpty) ...[
                              SizedBox(height: floorOps.isNotEmpty ? 20 : 0),
                              _SectionLabel(title: 'Supervisão'),
                              const SizedBox(height: 10),
                              _OperatorGrid(
                                operators: gestores,
                                selectedId: _selected?.id,
                                onSelect: _selectOperator,
                              ),
                            ],
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _selected == null
                                  ? Padding(
                                      key: const ValueKey('hint'),
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Text(
                                        'Selecione seu nome acima.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: DipontoColors.onSurface.withValues(alpha: 0.42),
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : _PinPanel(
                                      key: ValueKey(_selected!.id),
                                      operator: _selected!,
                                      controller: _pinController,
                                      focusNode: _pinFocus,
                                      locked: _isLocked,
                                      onChanged: () => setState(() {}),
                                      onSubmit: _submit,
                                    ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              _ErrorBanner(message: _error!),
                            ],
                            if (remaining != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Aguarde $remaining s para tentar de novo.',
                                style: const TextStyle(color: DipontoColors.primaryLight),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: (_loading || _isLocked || _selected == null) ? null : _submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
                                  : const Text('Entrar no turno'),
                            ),
                            _DemoFooter(
                              enteringDemo: _enteringDemo,
                              loading: _loading,
                              locked: _isLocked,
                              onDemo: _enterDemoMode,
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
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DipontoBrandMark(size: 64, borderRadius: 14),
        const SizedBox(height: 14),
        SvgPicture.asset(
          AppAssets.brandWordmark,
          height: 28,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => Image.asset(
            AppAssets.splashLogo,
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Validador de Sirenes',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: DipontoColors.onSurface.withValues(alpha: 0.45),
                letterSpacing: 0.6,
              ),
        ),
      ],
    );
  }
}

class _LoginShell extends StatelessWidget {
  const _LoginShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DipontoColors.cardElevated.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DipontoColors.primary.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: child,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DipontoColors.onSurface.withValues(alpha: 0.45),
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _OperatorGrid extends StatelessWidget {
  const _OperatorGrid({
    required this.operators,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Operator> operators;
  final int? selectedId;
  final ValueChanged<Operator> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 340;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final op in operators)
              SizedBox(
                width: twoColumns
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth,
                child: _OperatorCard(
                  operator: op,
                  selected: selectedId == op.id,
                  onTap: () => onSelect(op),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OperatorCard extends StatelessWidget {
  const _OperatorCard({
    required this.operator,
    required this.selected,
    required this.onTap,
  });

  final Operator operator;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(operator);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Material(
      color: selected
          ? DipontoColors.primary.withValues(alpha: 0.14)
          : DipontoColors.surfaceVariant.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? DipontoColors.primary
                  : DipontoColors.onSurface.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: selected
                    ? DipontoColors.primary.withValues(alpha: 0.28)
                    : DipontoColors.surface,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? DipontoColors.primary
                        : DipontoColors.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: selected ? DipontoColors.primary : DipontoColors.onSurface,
                      ),
                    ),
                    if (operator.isGestor)
                      Text(
                        'Gestor',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DipontoColors.primaryLight.withValues(alpha: 0.85),
                            ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? DipontoColors.primary
                    : DipontoColors.onSurface.withValues(alpha: 0.25),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPanel extends StatefulWidget {
  const _PinPanel({
    super.key,
    required this.operator,
    required this.controller,
    required this.focusNode,
    required this.locked,
    required this.onChanged,
    required this.onSubmit,
  });

  final Operator operator;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool locked;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  State<_PinPanel> createState() => _PinPanelState();
}

class _PinPanelState extends State<_PinPanel> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});
  void _onTextChange() {
    setState(() {});
    widget.onChanged();
    final pin = widget.controller.text;
    if (!widget.locked && pin.length == widget.operator.codigo.length) {
      widget.onSubmit();
    }
  }

  void _focusField() {
    if (!widget.locked) widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = widget.controller.text.isNotEmpty;
    final focused = widget.focusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _focusField,
          borderRadius: BorderRadius.circular(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DipontoColors.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focused
                    ? DipontoColors.primary.withValues(alpha: 0.55)
                    : DipontoColors.primary.withValues(alpha: 0.2),
                width: focused ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  TextFormField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'PIN de ${_displayName(widget.operator)}',
                  hintText: hasPin ? null : 'Digite seu PIN',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    letterSpacing: 0,
                    color: DipontoColors.onSurface.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: hasPin
                      ? IconButton(
                          tooltip: 'Limpar',
                          onPressed: () {
                            widget.controller.clear();
                            widget.onChanged();
                            _focusField();
                          },
                          icon: const Icon(Icons.close, size: 18),
                        )
                      : IconButton(
                          tooltip: 'Digitar PIN',
                          onPressed: _focusField,
                          icon: Icon(
                            Icons.dialpad,
                            color: DipontoColors.primary.withValues(alpha: 0.75),
                          ),
                        ),
                ),
                style: TextStyle(
                  fontSize: hasPin ? 24 : 18,
                  letterSpacing: hasPin ? 8 : 0,
                  fontWeight: hasPin ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                obscureText: hasPin,
                obscuringCharacter: '•',
                enableSuggestions: false,
                autocorrect: false,
                enabled: !widget.locked,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.operator.codigo.length),
                ],
                onChanged: (_) => _onTextChange(),
                onFieldSubmitted: (_) => widget.onSubmit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o PIN';
                  return null;
                },
                  ),
                  const SizedBox(height: 14),
                  _NumericKeypad(
                    enabled: !widget.locked,
                    onDigit: (digit) {
                      if (widget.controller.text.length >= widget.operator.codigo.length) return;
                      widget.controller.text += digit;
                      _onTextChange();
                    },
                    onBackspace: () {
                      if (widget.controller.text.isEmpty) return;
                      widget.controller.text =
                          widget.controller.text.substring(0, widget.controller.text.length - 1);
                      _onTextChange();
                    },
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

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: key.isEmpty
                          ? const SizedBox(height: 52)
                          : SizedBox(
                              height: 52,
                              child: key == '⌫'
                                  ? OutlinedButton(
                                      onPressed: enabled ? onBackspace : null,
                                      child: const Icon(Icons.backspace_outlined, size: 20),
                                    )
                                  : FilledButton.tonal(
                                      onPressed: enabled ? () => onDigit(key) : null,
                                      style: FilledButton.styleFrom(
                                        textStyle: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: Text(key),
                                    ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DipontoColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DipontoColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: DipontoColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: DipontoColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoFooter extends StatelessWidget {
  const _DemoFooter({
    required this.enteringDemo,
    required this.loading,
    required this.locked,
    required this.onDemo,
  });

  final bool enteringDemo;
  final bool loading;
  final bool locked;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        Divider(color: DipontoColors.onSurface.withValues(alpha: 0.1)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: (loading || enteringDemo || locked) ? null : onDemo,
          icon: enteringDemo
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.smart_display_outlined, size: 18),
          label: Text(enteringDemo ? 'Preparando demo…' : 'Modo demonstração'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.deepPurpleAccent,
          ),
        ),
        Text(
          'Sem ESP32 ou Firebase · gestor demo PIN $kDemoGestorPin',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DipontoColors.onSurface.withValues(alpha: 0.38),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

String _displayName(Operator op) {
  final n = op.nome.trim();
  if (n.isEmpty) return op.codigo;
  return n[0].toUpperCase() + n.substring(1);
}
