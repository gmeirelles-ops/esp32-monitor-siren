import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';

/// Card de seção para agrupar blocos de configuração.
class FormSectionCard extends StatelessWidget {
  const FormSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DipontoColors.cardElevated,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
