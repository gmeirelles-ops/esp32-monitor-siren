import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/global_app_bar_actions.dart';
import '../../shared/widgets/responsive_field_row.dart';
import '../cloud/auth/auth_providers.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../products/products_provider.dart';

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

  /// Carrega contador e reconciliação para o produto/ano atuais e
  /// pré-preenche o próximo sequencial sugerido.
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

  Future<void> _sendSetBatch(Product product) async {
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
      await notifier.sendSetBatch(deviceId, batch);
      final ok = await notifier.waitForState(deviceId, DeviceFsmState.batchReady);
      if (!mounted) return;
      if (ok) {
        _showSnack('Lote configurado com sucesso');
      } else {
        _showSnack('Timeout aguardando BATCH_READY — tente novamente');
      }
    } catch (e) {
      _showSnack('Erro: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendEndBatch() async {
    final deviceId = _selectedDeviceId;
    if (deviceId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar lote?'),
        content: const Text('Isso limpará o lote ativo no dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Encerrar')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _sending = true);
    try {
      final notifier = ref.read(devicesProvider.notifier);
      await notifier.sendEndBatch(deviceId);
      final ok = await notifier.waitForState(deviceId, DeviceFsmState.idle);
      if (!mounted) return;
      _showSnack(ok ? 'Lote encerrado' : 'Timeout aguardando IDLE');
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
    final estado = device?.estado ?? DeviceFsmState.unknown;
    final batch = device?.activeBatch;
    final lastTest = device?.lastTestResult;
    final aprovados = lastTest?.aprovadosNoLote ?? 0;
    final total = batch?.quantidadeTotal ?? 0;

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

    ref.listen(printFailureProvider, (prev, next) {
      if (next != null) {
        _showSnack(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lote'),
        actions: globalAppBarActions(),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: 'Nenhum produto cadastrado',
              subtitle:
                  'Vá em Produtos e cadastre um SKU com autocalibração antes de configurar o lote.',
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
              if (deviceList.isEmpty)
                const Text('Nenhum dispositivo detectado ainda.')
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedDeviceId,
                  decoration: const InputDecoration(labelText: 'Dispositivo'),
                  items: deviceList
                      .map((d) => DropdownMenuItem(value: d.deviceId, child: Text(d.deviceId)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedDeviceId = v);
                    ref.read(selectedDeviceIdProvider.notifier).state = v;
                    ref.read(appConfigProvider).setSelectedDeviceId(v);
                  },
                ),
              const SizedBox(height: 16),
              if (estado == DeviceFsmState.batchReady)
                Card(
                  color: DipontoColors.primary.withValues(alpha: 0.15),
                  child: const ListTile(
                    leading: Icon(Icons.touch_app, color: DipontoColors.primary),
                    title: Text('Pressione o botão no dispositivo'),
                    subtitle: Text('O teste só inicia pelo botão físico'),
                  ),
                ),
              if (estado == DeviceFsmState.testing)
                const Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: DipontoColors.primary),
                    ),
                    title: Text('Teste em andamento...'),
                  ),
                ),
              if (total > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total > 0 ? (aprovados / total).clamp(0.0, 1.0) : 0,
                  color: DipontoColors.primary,
                  backgroundColor: DipontoColors.surfaceVariant,
                ),
                Text('$aprovados / $total aprovados'),
                if (aprovados >= total)
                  const Text(
                    'Meta atingida — considere encerrar o lote',
                    style: TextStyle(color: DipontoColors.primaryLight),
                  ),
              ],
              if (lastTest != null) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final operador = ref.watch(authStateProvider).valueOrNull?.email;
                    return Card(
                      color: lastTest.isApproved
                          ? DipontoColors.success.withValues(alpha: 0.15)
                          : DipontoColors.error.withValues(alpha: 0.15),
                      child: ListTile(
                        title: Text(lastTest.veredito),
                        subtitle: Text(
                          '${lastTest.potenciaMedia.toStringAsFixed(2)} W — seq ${lastTest.sequencial}'
                          '${operador != null ? '\nOperador: $operador' : ''}',
                        ),
                        isThreeLine: operador != null,
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProductId,
                      decoration: const InputDecoration(labelText: 'Produto'),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p.idProduto,
                                child: Text('${p.idProduto} — ${p.nome}'),
                              ))
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
                          validator: (v) => v == null || v.length != 2 ? '2 dígitos' : null,
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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: _sending || product == null ? null : () => _sendSetBatch(product),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Configurar lote (SET_BATCH)'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DipontoColors.error,
                    side: const BorderSide(color: DipontoColors.error),
                  ),
                  onPressed: _sending ? null : _sendEndBatch,
                  child: const Text('Encerrar lote (END_BATCH)'),
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
