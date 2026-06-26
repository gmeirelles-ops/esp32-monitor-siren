import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/form_section_card.dart';
import '../bancadas/bancadas_provider.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../products/products_provider.dart';
import '../setup/posto_setup_screen.dart';
import 'batch_live_screen.dart';
import 'batch_serial_logic.dart';
import 'batch_today_providers.dart';

class BatchScreen extends ConsumerStatefulWidget {
  const BatchScreen({super.key});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroOp = TextEditingController();
  final _quantidadeTotal = TextEditingController(text: '10');

  bool _sending = false;
  String? _selectedProductId;

  @override
  void dispose() {
    _numeroOp.dispose();
    _quantidadeTotal.dispose();
    super.dispose();
  }

  Product? _selectedProduct(List<Product> products) {
    if (_selectedProductId == null) return null;
    for (final p in products) {
      if (p.idProduto == _selectedProductId) return p;
    }
    return null;
  }

  bool _validateForm(Product product) {
    return _formKey.currentState!.validate();
  }

  void _openLiveDashboard(String deviceId, String numeroOp) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BatchLiveScreen(deviceId: deviceId, numeroOp: numeroOp),
      ),
    );
  }

  void _openPostoSetup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PostoSetupScreen()),
    );
  }

  void _openSettings() {
    // Shell index 5 = Configurações — navegação interna não disponível aqui;
    // operador usa menu lateral. SnackBar orienta.
    _showSnack('Abra Configurações → Manutenção do posto para alterar a bancada');
  }

  Future<void> _sendSetBatch(Product product) async {
    if (!ref.read(bancadaSetupCompleteProvider)) {
      _showSnack('Configure a bancada do posto antes de iniciar o lote');
      _openPostoSetup();
      return;
    }

    final deviceId = ref.read(selectedDeviceIdProvider) ?? ref.read(appConfigProvider).selectedDeviceId;
    if (deviceId == null) {
      _showSnack('Nenhuma bancada vinculada a este posto');
      _openPostoSetup();
      return;
    }
    if (!_validateForm(product)) return;

    final ano = resolveBatchYear();
    final db = ref.read(databaseProvider);
    final proximoSequencial = await resolveProximoSequencial(db, product.idProduto, ano);

    final batch = BatchConfig(
      numeroOp: _numeroOp.text.trim(),
      idProduto: product.idProduto,
      ano: ano,
      tempoTeste: product.tempoTesteSec,
      potenciaMin: product.potenciaMin,
      potenciaMax: product.potenciaMax,
      quantidadeTotal: int.parse(_quantidadeTotal.text),
      proximoSequencial: proximoSequencial,
    );

    if (await db.isOpLocked(batch.numeroOp)) {
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
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final productsAsync = ref.watch(productsStreamProvider);
    final bancadaReady = ref.watch(bancadaSetupCompleteProvider);
    final todayAsync = ref.watch(batchTodaySummaryProvider);
    final deviceId = ref.watch(selectedDeviceIdProvider) ?? ref.watch(appConfigProvider).selectedDeviceId;
    final device = deviceId != null ? devices[deviceId] : null;
    final activeBatch = device?.activeBatch;

    ref.listen(latestRejectionProvider, (prev, next) {
      if (next != null) {
        _showSnack('Rejeição (${next.deviceId}): ${next.rejection.motivo}');
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

          return ListView(
            children: [
              DesktopFormLayout(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormSectionCard(
                      title: 'Turno',
                      child: todayAsync.when(
                        loading: () => const Text('Carregando…'),
                        error: (_, __) => const Text('—'),
                        data: (summary) => Text(
                          'Testes hoje: ${summary.total} '
                          '(${summary.aprovados} aprovados, ${summary.reprovados} reprovados)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    FormSectionCard(
                      title: 'Bancada',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!bancadaReady || deviceId == null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Nenhuma bancada vinculada a este posto.',
                                  style: TextStyle(color: Colors.orangeAccent),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _openPostoSetup,
                                  child: const Text('Configurar bancada'),
                                ),
                              ],
                            )
                          else
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.circle,
                                size: 12,
                                color: device?.isOnline == true
                                    ? DipontoColors.success
                                    : DipontoColors.error,
                              ),
                              title: Text(formatBancadaLabelFromMap(deviceId, bancadas)),
                              subtitle: Text(
                                device?.isOnline == true ? 'Conectada' : 'Offline',
                              ),
                              trailing: TextButton(
                                onPressed: _openSettings,
                                child: const Text('Alterar em Configurações'),
                              ),
                            ),
                          if (activeBatch != null && deviceId != null) ...[
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
                                onTap: () => _openLiveDashboard(deviceId, activeBatch.numeroOp),
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
                              onChanged: (v) => setState(() => _selectedProductId = v),
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
                            TextFormField(
                              controller: _quantidadeTotal,
                              decoration: const InputDecoration(labelText: 'Quantidade total'),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ),
                    FormSectionCard(
                      title: 'Ações',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: _sending || product == null || !bancadaReady || deviceId == null
                              ? null
                              : () => _sendSetBatch(product),
                          child: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('INICIAR'),
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
