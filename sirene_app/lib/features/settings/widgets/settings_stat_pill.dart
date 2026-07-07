import 'package:flutter/material.dart';

import '../../../core/theme/diponto_theme.dart';

class SettingsStatPill extends StatelessWidget {
  const SettingsStatPill({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DipontoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DipontoColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
