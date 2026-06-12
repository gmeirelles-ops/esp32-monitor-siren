import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import '../../features/operators/operator_selector_sheet.dart';
import '../../features/operators/operators_provider.dart';

/// Chip compacto na AppBar para o operador ativo do turno.
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
      error: (_, __) => _chip(context, ref, label: 'Operador', warning: true),
      data: (op) {
        if (op == null) {
          return _chip(context, ref, label: compact ? 'Turno' : 'Selecionar operador', warning: true);
        }
        final label = compact ? op.codigo : '${op.nome} (${op.codigo})';
        return _chip(context, ref, label: label, warning: false);
      },
    );
  }

  Widget _chip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool warning,
  }) {
    final color = warning ? DipontoColors.error : DipontoColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ActionChip(
        avatar: Icon(Icons.badge_outlined, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        onPressed: () => showOperatorSelector(context, ref),
      ),
    );
  }
}
