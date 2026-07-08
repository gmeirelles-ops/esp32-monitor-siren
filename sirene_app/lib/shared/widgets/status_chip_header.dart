import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';

class StatusChipData {
  const StatusChipData({
    required this.icon,
    required this.label,
    required this.color,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool highlight;
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
            _StatusChip(
              icon: chip.icon,
              label: chip.label,
              color: chip.color,
              highlight: chip.highlight,
            ),
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
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: highlight ? 14 : 12,
        vertical: highlight ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlight ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(highlight ? 24 : 20),
        border: Border.all(
          color: color.withValues(alpha: highlight ? 0.55 : 0.35),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: highlight ? 18 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: highlight ? 14 : 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? color : DipontoColors.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
