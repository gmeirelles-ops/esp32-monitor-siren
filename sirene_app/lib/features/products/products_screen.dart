import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import 'product_form_screen.dart';
import 'products_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            tooltip: 'Novo produto',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum produto cadastrado.\n'
                  'Cadastre um SKU com peça padrão na bancada para definir os limites de potência.',
                  textAlign: TextAlign.center,
                ),
              ),
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
                    '(ref ${p.potenciaRef.toStringAsFixed(2)} W, ±${p.toleranciaPct.toStringAsFixed(0)}%)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductFormScreen(existing: p),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DipontoColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
