import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';

class DipontoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DipontoAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
          Text(title),
        ],
      ),
      actions: actions,
    );
  }
}
