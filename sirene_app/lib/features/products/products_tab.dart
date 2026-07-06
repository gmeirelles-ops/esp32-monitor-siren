import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_page_layout.dart';
import '../../shared/widgets/section_intro.dart';
import 'product_form_screen.dart';
import 'products_provider.dart';

/// Lista de produtos para embutir na tela Cadastros (sem Scaffold próprio).
class ProductsTab extends ConsumerWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (products) {
        if (products.isEmpty) {
          return const EmptyStateView(
            icon: Icons.inventory_2_outlined,
            title: 'Nenhum produto cadastrado',
            subtitle:
                'Cadastre um SKU com peça padrão na bancada para definir os limites de potência.',
            showProgress: false,
          );
        }

        return ScreenPageLayout(
          intro: const SectionIntro(
            title: 'Catálogo de produtos',
            subtitle: 'SKUs com limites de potência e tempo de teste para os lotes.',
            icon: Icons.inventory_2_outlined,
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            for (final p in products)
              ActionSectionCard(
                icon: Icons.category_outlined,
                title: '${p.idProduto} — ${p.nome}',
                subtitle:
                    '${p.potenciaMin.toStringAsFixed(2)}–${p.potenciaMax.toStringAsFixed(2)} W '
                    '(ref ${p.potenciaRef.toStringAsFixed(2)} W)',
                trailing: const Icon(Icons.chevron_right),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _openForm(context, existing: p),
                    child: const Text('Editar produto'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openForm(BuildContext context, {Product? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductFormScreen(existing: existing),
      ),
    );
  }
}
