import 'package:flutter/material.dart';

import '../../core/constants/layout.dart';

/// Linha de campos em desktop; coluna empilhada em mobile.
class ResponsiveFieldRow extends StatelessWidget {
  const ResponsiveFieldRow({
    super.key,
    required this.children,
    this.flexes,
    this.spacing = 12,
  });

  final List<Widget> children;
  final List<int>? flexes;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    final flexValues = flexes ?? List.filled(children.length, 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(flex: flexValues[i], child: children[i]),
        ],
      ],
    );
  }
}
