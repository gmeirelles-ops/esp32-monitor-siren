import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';

enum AppMessageKind { info, success, warning, error }

/// Aviso destacado no **topo** da tela — some sozinho após [duration].
void showAppMessage(
  BuildContext context,
  String message, {
  AppMessageKind? kind,
  Duration duration = const Duration(seconds: 2),
}) {
  final resolved = kind ?? _inferKind(message);
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..hideCurrentMaterialBanner();

  final (Color bg, Color fg, IconData icon) = switch (resolved) {
    AppMessageKind.success => (DipontoColors.success, Colors.white, Icons.check_circle_outline),
    AppMessageKind.warning => (
        const Color(0xFFE65100),
        Colors.white,
        Icons.warning_amber_rounded,
      ),
    AppMessageKind.error => (DipontoColors.error, Colors.white, Icons.error_outline),
    AppMessageKind.info => (DipontoColors.primary, DipontoColors.onPrimary, Icons.info_outline),
  };

  final media = MediaQuery.of(context);
  final top = media.padding.top + 8;
  const estimatedHeight = 88.0;
  final bottomMargin = (media.size.height - top - estimatedHeight).clamp(120.0, media.size.height * 0.82);

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 12,
      duration: duration,
      backgroundColor: bg,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

AppMessageKind _inferKind(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('erro') ||
      lower.contains('rejeitado') ||
      lower.contains('falha') ||
      lower.contains('não foi possível')) {
    return AppMessageKind.error;
  }
  if (lower.contains('duplicado') ||
      lower.contains('já existe') ||
      lower.contains('já gravado') ||
      lower.contains('aguarde')) {
    return AppMessageKind.warning;
  }
  if (lower.contains('encerrado') ||
      lower.contains('registrado') ||
      lower.contains('salvo') ||
      lower.contains('concluída')) {
    return AppMessageKind.success;
  }
  return AppMessageKind.info;
}
