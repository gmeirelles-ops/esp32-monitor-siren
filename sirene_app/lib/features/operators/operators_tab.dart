import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_page_layout.dart';
import '../../shared/widgets/section_intro.dart';
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

        return ScreenPageLayout(
          intro: const SectionIntro(
            title: 'Operadores do posto',
            subtitle: 'Cadastro de operadores e perfil gestor. O PIN não é exibido na lista.',
            icon: Icons.badge_outlined,
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            for (final op in operators)
              ActionSectionCard(
                icon: Icons.person_outline,
                title: op.nome,
                subtitle: '${op.ativo ? 'Ativo' : 'Inativo'}${op.isGestor ? ' · Gestor' : ''}',
                accentColor: op.ativo ? DipontoColors.primary : Colors.grey,
                trailing: const Icon(Icons.chevron_right),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _openForm(context, existing: op),
                    child: const Text('Editar operador'),
                  ),
                ),
              ),
          ],
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
