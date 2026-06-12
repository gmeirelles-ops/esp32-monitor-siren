import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import '../mqtt/mqtt_providers.dart';
import 'operators_provider.dart';

Future<void> showOperatorSelector(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _OperatorSelectorSheet(ref: ref),
  );
}

class _OperatorSelectorSheet extends ConsumerWidget {
  const _OperatorSelectorSheet({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef sheetRef) {
    final operatorsAsync = sheetRef.watch(activeOperatorsStreamProvider);
    final activeId = sheetRef.watch(appConfigProvider).activeOperatorId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Operador do turno',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            operatorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e'),
              data: (operators) {
                if (operators.isEmpty) {
                  return const Text(
                    'Nenhum operador ativo cadastrado. Vá em Cadastros → Operadores.',
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: operators.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final op = operators[index];
                      final selected = op.id == activeId;
                      return ListTile(
                        leading: Icon(
                          selected ? Icons.check_circle : Icons.person_outline,
                          color: selected ? DipontoColors.primary : null,
                        ),
                        title: Text(op.nome),
                        subtitle: Text(op.codigo),
                        onTap: () async {
                          await setActiveOperator(ref, op.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
