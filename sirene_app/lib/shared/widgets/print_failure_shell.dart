import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/mqtt/mqtt_providers.dart';
import '../../features/labels/marking_providers.dart';

/// Escuta falhas de impressão/gravação e exibe MaterialBanner global até limpar o provider.
class PrintFailureShell extends ConsumerWidget {
  const PrintFailureShell({super.key, required this.child});

  final Widget child;

  void _showBanner(BuildContext context, WidgetRef ref, String message, VoidCallback onDismiss) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
        backgroundColor: Colors.orange.withValues(alpha: 0.15),
        actions: [
          TextButton(onPressed: onDismiss, child: const Text('Dispensar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(printFailureProvider, (prev, next) {
      if (next != null) {
        _showBanner(context, ref, next, () {
          ref.read(printFailureProvider.notifier).state = null;
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        });
      } else if (prev != null) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });

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
