import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/empty_state_view.dart';
import 'operator_form_screen.dart';
import 'operators_provider.dart';

class OperatorsTab extends ConsumerWidget {
  const OperatorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operatorsAsync = ref.watch(operatorsStreamProvider);

    return operatorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (operators) {
        if (operators.isEmpty) {
          return const EmptyStateView(
            icon: Icons.badge_outlined,
            title: 'Nenhum operador cadastrado',
            subtitle: 'Cadastre os operadores do turno para rastreabilidade nos testes.',
            showProgress: false,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: operators.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final op = operators[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  Icons.person,
                  color: op.ativo ? DipontoColors.primary : Colors.grey,
                ),
                title: Text(op.nome),
                subtitle: Text('${op.codigo}${op.ativo ? '' : ' · inativo'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openForm(context, existing: op),
              ),
            );
          },
        );
      },
    );
  }

  void _openForm(BuildContext context, {Operator? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OperatorFormScreen(existing: existing),
      ),
    );
  }
}
