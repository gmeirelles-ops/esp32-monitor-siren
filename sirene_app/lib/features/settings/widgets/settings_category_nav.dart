import 'package:flutter/material.dart';

import '../../../core/theme/diponto_theme.dart';
import '../settings_category.dart';

class SettingsCategoryNav extends StatelessWidget {
  const SettingsCategoryNav({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final SettingsCategory selected;
  final ValueChanged<SettingsCategory> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            for (final cat in SettingsCategory.values) ...[
              _CompactTab(
                category: cat,
                selected: cat == selected,
                onTap: () => onSelected(cat),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }

    return Container(
      width: 240,
      color: DipontoColors.surfaceVariant.withValues(alpha: 0.45),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Text(
              'Seções',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DipontoColors.primary,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
          for (final cat in SettingsCategory.values)
            _NavTile(
              category: cat,
              selected: cat == selected,
              onTap: () => onSelected(cat),
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SettingsCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? DipontoColors.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: DipontoColors.primary.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  size: 22,
                  color: selected ? DipontoColors.primary : DipontoColors.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? DipontoColors.primary : DipontoColors.onSurface,
                        ),
                      ),
                      Text(
                        category.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DipontoColors.onSurface.withValues(alpha: 0.55),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactTab extends StatelessWidget {
  const _CompactTab({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SettingsCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        category.icon,
        size: 18,
        color: selected ? DipontoColors.onPrimary : DipontoColors.primaryLight,
      ),
      label: Text(category.title),
      selectedColor: DipontoColors.primary,
      labelStyle: TextStyle(
        color: selected ? DipontoColors.onPrimary : DipontoColors.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
