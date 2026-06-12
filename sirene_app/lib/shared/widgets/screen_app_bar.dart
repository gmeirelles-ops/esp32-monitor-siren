import 'package:flutter/material.dart';

import '../../core/constants/layout.dart';
import 'diponto_app_bar.dart';

/// AppBar de tela: no desktop o shell já exibe título + operador + MQTT.
PreferredSizeWidget? screenAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

  if (isDesktop) {
    final hasActions = actions != null && actions.isNotEmpty;
    final hasBottom = bottom != null;
    if (!hasActions && !hasBottom) return null;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: hasActions ? kToolbarHeight : 0,
      title: const SizedBox.shrink(),
      bottom: bottom,
      actions: actions,
    );
  }

  return DipontoAppBar(
    title: title,
    actions: actions,
    bottom: bottom,
  );
}
