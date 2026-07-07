import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';

/// Faixa visível quando o modo demonstração está ativo.
class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: 0.35),
            DipontoColors.primary.withValues(alpha: 0.25),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            compact ? Icons.slideshow : Icons.smart_display_outlined,
            color: Colors.deepPurpleAccent,
            size: compact ? 18 : 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              compact
                  ? 'Modo demonstração — testes simulados'
                  : 'Modo demonstração — bancada virtual, testes simulados (sem hardware)',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: DipontoColors.onSurface.withValues(alpha: 0.95),
              ),
            ),
          ),
          if (!compact)
            const Text(
              'Desative em Configurações → Manutenção',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}
