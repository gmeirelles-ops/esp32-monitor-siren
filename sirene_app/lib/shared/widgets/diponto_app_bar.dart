import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';
import 'active_operator_chip.dart';
import 'global_app_bar_actions.dart';

class DipontoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DipontoAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DipontoColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  color: DipontoColors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ),
      bottom: bottom,
      actions: [
        const ActiveOperatorChip(compact: true),
        ...globalAppBarActions(actions),
      ],
    );
  }
}
