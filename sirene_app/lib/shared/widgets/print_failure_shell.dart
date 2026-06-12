import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/mqtt/mqtt_providers.dart';

/// Escuta falhas de impressão e exibe MaterialBanner global até limpar o provider.
class PrintFailureShell extends ConsumerWidget {
  const PrintFailureShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(printFailureProvider, (prev, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next != null) {
        messenger.hideCurrentMaterialBanner();
        messenger.showMaterialBanner(
          MaterialBanner(
            content: Text(next),
            leading: const Icon(Icons.print_disabled, color: Colors.orangeAccent),
            backgroundColor: Colors.orange.withValues(alpha: 0.15),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(printFailureProvider.notifier).state = null;
                  messenger.hideCurrentMaterialBanner();
                },
                child: const Text('Dispensar'),
              ),
            ],
          ),
        );
      } else if (prev != null) {
        messenger.hideCurrentMaterialBanner();
      }
    });

    return child;
  }
}
