import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../mqtt/mqtt_providers.dart';
import 'laser_operator_copy.dart';
import 'mark_queue_ui.dart';

/// Banner destacado: próximo serial na fila + instrução do pedal.
class LaserMarkCallout extends ConsumerWidget {
  const LaserMarkCallout({required this.entry, super.key});

  final MarkQueueEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: resolveModelNameFromSerial(ref.read(databaseProvider), entry.serial),
      builder: (context, snapshot) {
        final modelo = snapshot.data;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: DipontoColors.primary.withValues(alpha: 0.18),
            border: Border.all(color: DipontoColors.primary.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.touch_app, color: DipontoColors.primary, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LaserOperatorCopy.triggerTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: DipontoColors.primary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      modelo != null
                          ? 'Próximo: ${entry.serial} ($modelo)'
                          : 'Próximo: ${entry.serial}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void showLaserEnqueuedFeedback(
  BuildContext context, {
  required String serial,
  String? modelo,
}) {
  final text = LaserOperatorCopy.enqueuedSnack(serial, modelo: modelo);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        duration: const Duration(seconds: 10),
        backgroundColor: DipontoColors.primary,
        content: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
}
