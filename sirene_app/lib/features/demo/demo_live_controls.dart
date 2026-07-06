import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/action_section_card.dart';
import '../demo/demo_playback.dart';
import '../demo/demo_providers.dart';

/// Controles de simulação no painel ao vivo (modo demo ou debug).
class DemoLiveControls extends ConsumerWidget {
  const DemoLiveControls({
    super.key,
    required this.deviceId,
    required this.hasActiveBatch,
    required this.onSimulateOnce,
    this.simulating = false,
  });

  final String deviceId;
  final bool hasActiveBatch;
  final VoidCallback? onSimulateOnce;
  final bool simulating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoMode = ref.watch(demoModeProvider);
    final autoPlay = ref.watch(demoAutoPlayProvider);
    if (!demoMode && !kDebugMode) return const SizedBox.shrink();

    return ActionSectionCard(
      icon: Icons.play_circle_outline,
      title: demoMode ? 'Simulação (demonstração)' : 'Simulação (dev)',
      subtitle: demoMode
          ? 'Gere testes fictícios para apresentar o fluxo completo'
          : 'Potências aleatórias — operador dev-simulator',
      accentColor: demoMode ? Colors.deepPurpleAccent : Colors.orangeAccent,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: simulating || !hasActiveBatch ? null : onSimulateOnce,
            icon: simulating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bolt, size: 18),
            label: const Text('Simular 1 teste'),
          ),
          if (demoMode) ...[
            FilledButton.tonalIcon(
              onPressed: !hasActiveBatch || autoPlay
                  ? null
                  : () => ref.read(demoPlaybackProvider).start(deviceId),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Autoplay'),
            ),
            OutlinedButton.icon(
              onPressed: autoPlay ? () => ref.read(demoPlaybackProvider).stop() : null,
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('Parar autoplay'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DipontoColors.error,
                side: BorderSide(
                  color: autoPlay
                      ? DipontoColors.error
                      : DipontoColors.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
