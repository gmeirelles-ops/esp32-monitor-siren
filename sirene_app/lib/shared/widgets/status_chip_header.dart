import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';

class StatusChipData {
  const StatusChipData({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class StatusChipHeader extends StatelessWidget {
  const StatusChipHeader({
    super.key,
    required this.chips,
  });

  final List<StatusChipData> chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: DipontoColors.cardElevated,
        border: Border(
          bottom: BorderSide(color: DipontoColors.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final chip in chips)
            _StatusChip(icon: chip.icon, label: chip.label, color: chip.color),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: DipontoColors.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
