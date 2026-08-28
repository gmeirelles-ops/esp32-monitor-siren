import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';

import '../../features/labels/marking_providers.dart';

/// Escuta falhas de gravação laser e exibe MaterialBanner global até limpar o provider.
class PrintFailureShell extends ConsumerWidget {
  const PrintFailureShell({super.key, required this.child});

  final Widget child;

  void _showBanner(BuildContext context, WidgetRef ref, String message, VoidCallback onDismiss) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        leading: const Icon(Icons.error_outline, color: DipontoColors.error, size: 28),
        backgroundColor: DipontoColors.error.withValues(alpha: 0.18),
        elevation: 4,
        actions: [
          TextButton(
            onPressed: onDismiss,
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(markFailureProvider, (prev, next) {
      if (next != null) {
        _showBanner(context, ref, next, () {
          ref.read(markFailureProvider.notifier).state = null;
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        });
      } else if (prev != null) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });

    return child;
  }
}
