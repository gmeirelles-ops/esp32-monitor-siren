import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/sirene_colors.dart';
import 'cloud_auth_service.dart';
import 'firebase_auth_errors_pt.dart';

/// Tela de login Firebase — copiar para sirene_app e registrar rota.
///
/// Uso típico: Configurações → Nuvem, ou gate opcional antes de habilitar sync.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    this.onSuccess,
    this.onSkipOffline,
    this.initialStationId,
    this.onStationIdSaved,
  });

  final CloudAuthService authService;
  final VoidCallback? onSuccess;
  final VoidCallback? onSkipOffline;
  final String? initialStationId;
  final void Function(String stationId)? onStationIdSaved;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stationCtrl.text = widget.initialStationId ?? '';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _stationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.signIn(_emailCtrl.text, _passCtrl.text);
      final station = _stationCtrl.text.trim();
      if (station.isNotEmpty) {
        widget.onStationIdSaved?.call(station);
      }
      if (!mounted) return;
      widget.onSuccess?.call();
      Navigator.of(context).maybePop(true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = firebaseAuthErrorPt(e.code));
    } catch (_) {
      setState(() => _error = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Informe um e-mail válido para recuperar a senha.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link de recuperação enviado ao e-mail.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = firebaseAuthErrorPt(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: SireneColors.background,
      appBar: AppBar(
        backgroundColor: SireneColors.surface,
        foregroundColor: SireneColors.textPrimary,
        title: const Text('Sincronização na nuvem'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.cloud_sync, size: 56, color: SireneColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Entrar na nuvem',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: SireneColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O posto funciona sem internet. O login só é necessário '
                      'para sincronizar dados com o Firestore.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: SireneColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _field(
                      controller: _emailCtrl,
                      label: 'E-mail',
                      icon: Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                        if (!v.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _passCtrl,
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: SireneColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _stationCtrl,
                      label: 'ID do posto (station_id)',
                      icon: Icons.factory_outlined,
                      hint: 'ex.: posto-01',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe o ID do posto' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: SireneColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: SireneColors.primary,
                        foregroundColor: SireneColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: const Text('Esqueci a senha'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              widget.onSkipOffline?.call();
                              Navigator.of(context).maybePop(false);
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SireneColors.textSecondary,
                        side: const BorderSide(color: SireneColors.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continuar sem nuvem'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: SireneColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: SireneColors.textSecondary),
        hintStyle: TextStyle(color: SireneColors.textSecondary.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: SireneColors.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: SireneColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SireneColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SireneColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SireneColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SireneColors.error),
        ),
      ),
    );
  }
}
