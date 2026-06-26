import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../batch/batch_serial_logic.dart';
import '../products/products_provider.dart';

/// Painel de reconciliação de série (uso em Configurações).
class SerialReconciliationPanel extends ConsumerStatefulWidget {
  const SerialReconciliationPanel({super.key});

  @override
  ConsumerState<SerialReconciliationPanel> createState() => _SerialReconciliationPanelState();
}

class _SerialReconciliationPanelState extends ConsumerState<SerialReconciliationPanel> {
  String? _selectedProductId;
  SerialReconciliation? _reconciliation;
  bool _loading = false;

  Future<void> _load() async {
    final id = _selectedProductId;
    if (id == null) return;
    setState(() => _loading = true);
    final ano = resolveBatchYear();
    final recon = await ref.read(databaseProvider).reconcileSerials(id, ano);
    if (!mounted) return;
    setState(() {
      _reconciliation = recon;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return productsAsync.when(
      loading: () => const Text('Carregando produtos...'),
      error: (e, _) => Text('Erro: $e'),
      data: (products) {
        if (products.isEmpty) {
          return const Text('Cadastre um produto para verificar a série.');
        }
        _selectedProductId ??= products.first.idProduto;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              decoration: const InputDecoration(labelText: 'Produto'),
              items: [
                for (final p in products)
                  DropdownMenuItem(value: p.idProduto, child: Text(p.idProduto)),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedProductId = v;
                  _reconciliation = null;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Ano atual: ${resolveBatchYear()}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _loading ? null : _load,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verificar série'),
              ),
            ),
            if (_reconciliation != null) ...[
              const SizedBox(height: 12),
              _ReconciliationCard(reconciliation: _reconciliation!),
            ],
          ],
        );
      },
    );
  }
}

class _ReconciliationCard extends StatelessWidget {
  const _ReconciliationCard({required this.reconciliation});

  final SerialReconciliation reconciliation;

  String _fmt(List<int> seqs) => seqs.map((s) => s.toString().padLeft(4, '0')).join(', ');

  @override
  Widget build(BuildContext context) {
    if (reconciliation.isIntact) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.check_circle, color: DipontoColors.success),
          title: Text('Sequência íntegra'),
        ),
      );
    }

    return Card(
      color: DipontoColors.error.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.report_problem, color: DipontoColors.error, size: 18),
                SizedBox(width: 8),
                Text('Reconciliação de série', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            if (reconciliation.gaps.isNotEmpty)
              Text('Sequenciais faltando: ${_fmt(reconciliation.gaps)}'),
            if (reconciliation.duplicates.isNotEmpty)
              Text('Sequenciais duplicados: ${_fmt(reconciliation.duplicates)}'),
          ],
        ),
      ),
    );
  }
}
