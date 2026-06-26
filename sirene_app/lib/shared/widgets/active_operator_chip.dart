import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import '../../features/operators/operators_provider.dart';

/// Chip compacto na AppBar com o operador da sessão (somente leitura).
class ActiveOperatorChip extends ConsumerWidget {
  const ActiveOperatorChip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeOperatorProvider);

    return activeAsync.when(
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => _chip(label: 'Operador', warning: true),
      data: (op) {
        if (op == null) {
          return _chip(label: compact ? 'Turno' : 'Sem operador', warning: true);
        }
        final label = compact ? op.nome : '${op.nome} (${op.codigo})';
        final isGestor = ref.watch(activeOperatorIsGestorProvider);
        return _chip(
          label: label,
          warning: false,
          onTap: isGestor ? null : () => clearOperatorSession(ref),
        );
      },
    );
  }

  Widget _chip({required String label, required bool warning, VoidCallback? onTap}) {
    final color = warning ? DipontoColors.error : DipontoColors.primary;
    final chip = Chip(
      avatar: Icon(Icons.badge_outlined, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );

    if (onTap == null) {
      return Padding(padding: const EdgeInsets.only(right: 4), child: chip);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: 'Trocar operador',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: chip,
          ),
        ),
      ),
    );
  }
}
