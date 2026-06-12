import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/empty_state_view.dart';
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

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final p = products[index];
            return Card(
              child: ListTile(
                title: Text('${p.idProduto} — ${p.nome}'),
                subtitle: Text(
                  '${p.potenciaMin.toStringAsFixed(2)}–${p.potenciaMax.toStringAsFixed(2)} W '
                  '(ref ${p.potenciaRef.toStringAsFixed(2)} W)',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openForm(context, existing: p),
              ),
            );
          },
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
