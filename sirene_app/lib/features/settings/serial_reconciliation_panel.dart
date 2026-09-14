import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/dropdown_value.dart';
import '../batch/batch_serial_logic.dart';
import '../cloud/firebase_bootstrap.dart';
import '../cloud/sync/serial_catalog_service.dart';
import '../products/products_provider.dart';
import '../serial/itf_check_digit.dart';

/// Painel de reconciliação + alinhamento do contador de série.
class SerialReconciliationPanel extends ConsumerStatefulWidget {
  const SerialReconciliationPanel({super.key});

  @override
  ConsumerState<SerialReconciliationPanel> createState() =>
      _SerialReconciliationPanelState();
}

class _SerialReconciliationPanelState
    extends ConsumerState<SerialReconciliationPanel> {
  String? _selectedProductId;
  SerialReconciliation? _reconciliation;
  bool _loading = false;
  bool _aligning = false;
  int? _counter;
  int? _historyMax;
  int? _nextSeq;
  final _serialController = TextEditingController();

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final id = _selectedProductId;
    if (id == null) return;
    final db = ref.read(databaseProvider);
    final ano = resolveBatchYear();
    final counter = await db.getLastSequencial(id, ano);
    final historyMax = await db.maxSequencialInHistory(id, ano);
    final next = await resolveProximoSequencial(db, id, ano);
    if (!mounted) return;
    setState(() {
      _counter = counter;
      _historyMax = historyMax;
      _nextSeq = next;
    });
  }

  Future<void> _load() async {
    final id = _selectedProductId;
    if (id == null) return;
    setState(() => _loading = true);
    final ano = resolveBatchYear();
    final recon = await ref.read(databaseProvider).reconcileSerials(id, ano);
    await _refreshStatus();
    if (!mounted) return;
    setState(() {
      _reconciliation = recon;
      _loading = false;
    });
  }

  Future<void> _alignFromHistory() async {
    final id = _selectedProductId;
    if (id == null) return;
    setState(() => _aligning = true);
    try {
      final ano = resolveBatchYear();
      final aligned = await ref
          .read(databaseProvider)
          .alignSerialCounterFromHistory(id, ano);
      if (!mounted) return;
      if (aligned == null) {
        _snack(
          'Nenhum serial APROVADO/MANUAL no histórico local deste produto/ano',
        );
      } else {
        _snack('Contador alinhado ao histórico: último sequencial $aligned');
        await _refreshStatus();
      }
    } finally {
      if (mounted) setState(() => _aligning = false);
    }
  }

  Future<void> _alignFromSerial() async {
    final id = _selectedProductId;
    if (id == null) return;
    final raw = _serialController.text.trim();
    final err = validateItfSerialForProduct(raw, id);
    if (err != null) {
      _snack(err);
      return;
    }
    final anoSerial = parseAnoFromSerial(raw);
    final seq = parseSequencialFromSerial(raw);
    setState(() => _aligning = true);
    try {
      final aligned = await ref.read(databaseProvider).alignSerialCounter(
            idProduto: id,
            ano: anoSerial,
            sequencial: seq,
          );
      if (!mounted) return;
      _snack(
        'Contador ($id / $anoSerial) alinhado para $aligned '
        '(próximo será ${aligned + 1})',
      );
      await _refreshStatus();
    } finally {
      if (mounted) setState(() => _aligning = false);
    }
  }

  Future<void> _alignFromFirestore() async {
    final id = _selectedProductId;
    if (id == null) return;
    if (!isFirebaseAvailable || !ref.read(firebaseReadyProvider)) {
      _snack('Firebase indisponível neste posto');
      return;
    }
    setState(() => _aligning = true);
    try {
      final ano = resolveBatchYear();
      final yyyy = catalogYearFromBatchAno(ano);
      final maxSeq = await maxCatalogSequencial(
        firestore: FirebaseFirestore.instance,
        idProduto: id,
        yyyy: yyyy,
      );
      if (!mounted) return;
      if (maxSeq == null) {
        _snack('Nenhum serial no catálogo Firestore para $id / $yyyy');
        return;
      }
      final aligned = await ref.read(databaseProvider).alignSerialCounter(
            idProduto: id,
            ano: ano,
            sequencial: maxSeq,
          );
      if (!mounted) return;
      _snack('Contador alinhado ao Firestore: último sequencial $aligned');
      await _refreshStatus();
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao ler Firestore: $e');
    } finally {
      if (mounted) setState(() => _aligning = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final busy = _loading || _aligning;

    return productsAsync.when(
      loading: () => const Text('Carregando produtos...'),
      error: (e, _) => Text('Erro: $e'),
      data: (products) {
        if (products.isEmpty) {
          return const Text('Cadastre um produto para verificar a série.');
        }
        final productIds = products.map((p) => p.idProduto).toList();
        final selected = validDropdownValue(_selectedProductId, productIds) ??
            (productIds.isNotEmpty ? productIds.first : null);
        if (selected != _selectedProductId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedProductId = selected;
              _reconciliation = null;
            });
            _refreshStatus();
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(labelText: 'Produto'),
              items: [
                for (final p in products)
                  DropdownMenuItem(
                    value: p.idProduto,
                    child: Text('${p.idProduto} — ${p.nome}'),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (v) {
                      setState(() {
                        _selectedProductId = v;
                        _reconciliation = null;
                      });
                      _refreshStatus();
                    },
            ),
            const SizedBox(height: 8),
            Text(
              'Ano atual: ${resolveBatchYear()}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (_counter != null || _historyMax != null || _nextSeq != null) ...[
              const SizedBox(height: 8),
              Text(
                'Contador local: ${_counter ?? '—'}  ·  '
                'Máx. histórico: ${_historyMax ?? '—'}  ·  '
                'Próximo: ${_nextSeq ?? '—'}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Alinhar contador (manual + lote compartilham a mesma sequência):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : _alignFromHistory,
                  child: const Text('Pelo histórico local'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : _alignFromFirestore,
                  child: const Text('Pelo Firestore'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : _load,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verificar série'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serialController,
              decoration: const InputDecoration(
                labelText: 'Último serial já gravado',
                hintText: '0402600082',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: busy ? null : _alignFromSerial,
                child: const Text('Alinhar por este serial'),
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

  String _fmt(List<int> seqs) =>
      seqs.map((s) => s.toString().padLeft(4, '0')).join(', ');

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
                Text(
                  'Reconciliação de série',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Encontrados: ${reconciliation.found.length}'),
            if (reconciliation.gaps.isNotEmpty)
              Text('Sequenciais faltando: ${_fmt(reconciliation.gaps)}'),
            if (reconciliation.duplicates.isNotEmpty)
              Text(
                'Sequenciais duplicados: ${_fmt(reconciliation.duplicates)}',
              ),
          ],
        ),
      ),
    );
  }
}
