import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/active_operator_chip.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/responsive_field_row.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../operators/operator_selector_sheet.dart';
import '../operators/operators_provider.dart';
import '../products/products_provider.dart';
import 'batch_live_screen.dart';

class BatchScreen extends ConsumerStatefulWidget {
  const BatchScreen({super.key});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroOp = TextEditingController();
  final _ano = TextEditingController(text: '26');
  final _quantidadeTotal = TextEditingController(text: '10');
  final _proximoSequencial = TextEditingController(text: '1');

  bool _sending = false;
  String? _selectedDeviceId;
  String? _selectedProductId;

  int? _lastKnownSeq;
  SerialReconciliation? _reconciliation;
  String? _serialInfoKey;

  @override
  void dispose() {
    _numeroOp.dispose();
    _ano.dispose();
    _quantidadeTotal.dispose();
    _proximoSequencial.dispose();
    super.dispose();
  }

  Future<void> _loadSerialInfo(String idProduto, String ano) async {
    final key = '$idProduto|$ano';
    if (key == _serialInfoKey) return;
    _serialInfoKey = key;

    final db = ref.read(databaseProvider);
    final last = await db.getLastSequencial(idProduto, ano);
    final recon = await db.reconcileSerials(idProduto, ano);
    if (!mounted) return;
    setState(() {
      _lastKnownSeq = last;
      _reconciliation = recon;
      _proximoSequencial.text = '${(last ?? 0) + 1}';
    });
  }

  void _onProductOrYearChanged() {
    final id = _selectedProductId;
    final ano = _ano.text.trim();
    if (id != null && ano.length == 2) {
      _serialInfoKey = null;
      _loadSerialInfo(id, ano);
    }
  }

  Product? _selectedProduct(List<Product> products) {
    if (_selectedProductId == null) return null;
    for (final p in products) {
      if (p.idProduto == _selectedProductId) return p;
    }
    return null;
  }

  BatchConfig? _buildBatch(Product product) {
    if (!_formKey.currentState!.validate()) return null;
    return BatchConfig(
      numeroOp: _numeroOp.text.trim(),
      idProduto: product.idProduto,
      ano: _ano.text.trim(),
      tempoTeste: product.tempoTesteSec,
      potenciaMin: product.potenciaMin,
      potenciaMax: product.potenciaMax,
      quantidadeTotal: int.parse(_quantidadeTotal.text),
      proximoSequencial: int.parse(_proximoSequencial.text),
    );
  }

  void _openLiveDashboard(String deviceId, String numeroOp) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BatchLiveScreen(deviceId: deviceId, numeroOp: numeroOp),
      ),
    );
  }

  Future<void> _sendSetBatch(Product product) async {
    final activeOp = await ref.read(activeOperatorProvider.future);
    if (activeOp == null) {
      _showSnack('Selecione o operador do turno antes de configurar o lote');
      return;
    }

    final deviceId = _selectedDeviceId;
    if (deviceId == null) {
      _showSnack('Selecione um dispositivo');
      return;
    }
    final batch = _buildBatch(product);
    if (batch == null) return;

    if (await ref.read(databaseProvider).isOpLocked(batch.numeroOp)) {
      if (!mounted) return;
      _showSnack('OP ${batch.numeroOp} já encerrada — use uma nova OP');
      return;
    }

    setState(() => _sending = true);
    try {
      final notifier = ref.read(devicesProvider.notifier);
      final rejection = await notifier.sendSetBatch(deviceId, batch);
      if (!mounted) return;
      if (rejection != null) {
        _showSnack('Comando rejeitado: $rejection');
      } else {
        _openLiveDashboard(deviceId, batch.numeroOp);
      }
    } catch (e) {
      _showSnack('Erro: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final deviceList = devices.values.toList();
    _selectedDeviceId ??= ref.watch(selectedDeviceIdProvider) ??
        (deviceList.isNotEmpty ? deviceList.first.deviceId : null);

    final device = _selectedDeviceId != null ? devices[_selectedDeviceId] : null;
    final activeBatch = device?.activeBatch;

    ref.listen(latestRejectionProvider, (prev, next) {
      if (next != null) {
        _showSnack('Rejeição (${next.deviceId}): ${next.rejection.motivo}');
      }
    });

    ref.listen(duplicateSerialProvider, (prev, next) {
      if (next != null) {
        _showSnack('Serial duplicado bloqueado: ${next.serial} — etiqueta não emitida');
        _serialInfoKey = null;
        _onProductOrYearChanged();
      }
    });

    return Scaffold(
      appBar: screenAppBar(context, title: 'Lote'),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: 'Nenhum produto cadastrado',
              subtitle:
                  'Vá em Cadastros → Produtos e cadastre um SKU com autocalibração antes de configurar o lote.',
            );
          }

          _selectedProductId ??= products.first.idProduto;
          final product = _selectedProduct(products);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onProductOrYearChanged();
          });

          return ListView(
            children: [
              DesktopFormLayout(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormSectionCard(
                      title: 'Turno',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Operador responsável pelos testes deste turno.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ActiveOperatorChip(
                              compact: false,
                              key: ValueKey(_selectedDeviceId),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => showOperatorSelector(context, ref),
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Trocar operador'),
                          ),
                        ],
                      ),
                    ),
                    FormSectionCard(
                      title: 'Bancada',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (deviceList.isEmpty)
                            const Text('Nenhum dispositivo detectado ainda.')
                          else
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDeviceId,
                              decoration: const InputDecoration(labelText: 'Dispositivo'),
                              selectedItemBuilder: (context) => [
                                for (final d in deviceList)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      d.deviceId,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              items: deviceList
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d.deviceId,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 10,
                                            color: d.isOnline
                                                ? DipontoColors.success
                                                : DipontoColors.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(d.deviceId),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() => _selectedDeviceId = v);
                                ref.read(selectedDeviceIdProvider.notifier).state = v;
                                ref.read(appConfigProvider).setSelectedDeviceId(v);
                              },
                            ),
                          if (activeBatch != null && _selectedDeviceId != null) ...[
                            const SizedBox(height: 12),
                            Card(
                              color: DipontoColors.primary.withValues(alpha: 0.12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.dashboard_outlined,
                                  color: DipontoColors.primary,
                                ),
                                title: const Text('Lote em andamento'),
                                subtitle: Text('OP ${activeBatch.numeroOp}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    _openLiveDashboard(_selectedDeviceId!, activeBatch.numeroOp),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    FormSectionCard(
                      title: 'Produto e OP',
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedProductId,
                              decoration: const InputDecoration(labelText: 'Produto'),
                              items: products
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.idProduto,
                                      child: Text('${p.idProduto} — ${p.nome}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() => _selectedProductId = v);
                                _onProductOrYearChanged();
                              },
                            ),
                            if (product != null) ...[
                              const SizedBox(height: 8),
                              _ReadOnlyTile('Tempo teste', '${product.tempoTesteSec} s'),
                              _ReadOnlyTile(
                                'Potência mín',
                                '${product.potenciaMin.toStringAsFixed(2)} W',
                              ),
                              _ReadOnlyTile(
                                'Potência máx',
                                '${product.potenciaMax.toStringAsFixed(2)} W',
                              ),
                            ],
                            TextFormField(
                              controller: _numeroOp,
                              decoration: const InputDecoration(labelText: 'Número OP'),
                              validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                            ),
                            const SizedBox(height: 8),
                            ResponsiveFieldRow(
                              flexes: const [2, 3, 3],
                              children: [
                                TextFormField(
                                  controller: _ano,
                                  decoration: const InputDecoration(labelText: 'Ano (2 dígitos)'),
                                  validator: (v) =>
                                      v == null || v.length != 2 ? '2 dígitos' : null,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => _onProductOrYearChanged(),
                                ),
                                TextFormField(
                                  controller: _quantidadeTotal,
                                  decoration: const InputDecoration(labelText: 'Quantidade total'),
                                  keyboardType: TextInputType.number,
                                ),
                                TextFormField(
                                  controller: _proximoSequencial,
                                  decoration: InputDecoration(
                                    labelText: 'Próximo sequencial',
                                    helperText: _lastKnownSeq != null
                                        ? 'Último usado: $_lastKnownSeq'
                                        : 'Sem histórico',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                            if (_reconciliation != null && !_reconciliation!.isIntact) ...[
                              const SizedBox(height: 8),
                              _ReconciliationPanel(reconciliation: _reconciliation!),
                            ],
                          ],
                        ),
                      ),
                    ),
                    FormSectionCard(
                      title: 'Ações',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed:
                              _sending || product == null ? null : () => _sendSetBatch(product),
                          child: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Configurar lote (SET_BATCH)'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReconciliationPanel extends StatelessWidget {
  const _ReconciliationPanel({required this.reconciliation});

  final SerialReconciliation reconciliation;

  String _fmt(List<int> seqs) => seqs.map((s) => s.toString().padLeft(4, '0')).join(', ');

  @override
  Widget build(BuildContext context) {
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

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(color: DipontoColors.primaryLight)),
        ],
      ),
    );
  }
}
