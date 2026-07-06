import 'package:flutter/material.dart';

/// Layout padrão de tela: header opcional, intro, conteúdo com largura máxima.
class ScreenPageLayout extends StatelessWidget {
  const ScreenPageLayout({
    super.key,
    this.header,
    this.intro,
    required this.children,
    this.maxWidth = 900,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 32),
  });

  final Widget? header;
  final Widget? intro;
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        Expanded(
          child: SingleChildScrollView(
            padding: padding,
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (intro != null) intro!,
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Barra fixa inferior para ações primárias da tela.
class ScreenBottomBar extends StatelessWidget {
  const ScreenBottomBar({
    super.key,
    required this.child,
    this.hint,
  });

  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              if (hint != null)
                Expanded(
                  child: Text(
                    hint!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                const Spacer(),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
