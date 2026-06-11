import 'package:flutter/material.dart';

import '../../core/constants/layout.dart';

/// Centraliza e limita largura de formulários em desktop.
class DesktopFormLayout extends StatelessWidget {
  const DesktopFormLayout({
    super.key,
    required this.child,
    this.maxWidth = kFormMaxWidth,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
    final content = Padding(padding: padding, child: child);

    if (!isDesktop) return content;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}
