import 'package:flutter/material.dart';

import 'active_operator_chip.dart';
import 'diponto_brand_mark.dart';
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
          const DipontoBrandMark(size: 32),
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
