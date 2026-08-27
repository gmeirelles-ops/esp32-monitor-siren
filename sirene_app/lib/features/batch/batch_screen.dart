import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/layout.dart';
import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/responsive_field_row.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_page_layout.dart';
import '../../shared/widgets/section_intro.dart';
import '../../shared/widgets/status_chip_header.dart';
import '../../shared/dropdown_value.dart';
import '../bancadas/bancadas_provider.dart';
import '../demo/demo_constants.dart';
import '../demo/demo_providers.dart';
import '../demo/demo_service.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../products/power_limits.dart';
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
    _showSnack(
      'Peça ao gestor: Configurações → Manutenção do posto para alterar a bancada',
    );
  }

  Future<void> _sendSetBatch(Product product) async {
    final demoMode = ref.read(demoModeProvider);
    if (!demoMode && !ref.read(bancadaSetupCompleteProvider)) {
      _showSnack('Configure a bancada do posto antes de iniciar o lote');
      _openPostoSetup();
      return;
    }

    final deviceId = resolveActiveDeviceId(ref);
    if (deviceId == null) {
      _showSnack('Nenhuma bancada vinculada a este posto');
      if (!demoMode) _openPostoSetup();
      return;
    }
    if (!_validateForm(product)) return;

    final ano = resolveBatchYear();
    final db = ref.read(databaseProvider);
    final proximoSequencial = resolveNewBatchSequencial(
      sequencialInicial: product.sequencialInicial,
    );

    final batch = BatchConfig(
      numeroOp: _numeroOp.text.trim(),
      idProduto: product.idProduto,
      ano: ano,
      tempoTeste: product.tempoTesteSec,
      potenciaMin: roundPowerLimit(product.potenciaMin),
      potenciaMax: roundPowerLimit(product.potenciaMax),
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

  Widget _buildBottomBar({
    required Product? product,
    required bool bancadaReady,
    required String? deviceId,
    required BatchConfig? activeBatch,
  }) {
    if (activeBatch != null && deviceId != null) {
      return ScreenBottomBar(
        child: FilledButton.icon(
          onPressed: () => _openLiveDashboard(deviceId, activeBatch.numeroOp),
          icon: const Icon(Icons.play_circle_outline),
          label: Text('Continuar teste · OP ${activeBatch.numeroOp}'),
        ),
      );
    }

    final canStart = !_sending && product != null && bancadaReady && deviceId != null;

    return ScreenBottomBar(
      hint: !bancadaReady || deviceId == null ? 'Configure a bancada para iniciar' : null,
      child: FilledButton.icon(
        onPressed: canStart ? () => _sendSetBatch(product) : null,
        icon: _sending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: const Text('Iniciar lote'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final productsAsync = ref.watch(productsStreamProvider);
    final bancadaReady = ref.watch(bancadaSetupCompleteProvider);
    final demoMode = ref.watch(demoModeProvider);
    final todayAsync = ref.watch(batchTodaySummaryProvider);
    final deviceId = resolveActiveDeviceId(ref);
    final device = deviceId != null ? devices[deviceId] : null;
    final activeBatch = device?.activeBatch;

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
                  'Peça ao gestor para cadastrar um produto antes de iniciar o lote.',
            );
          }

          final productIds = products.map((p) => p.idProduto).toList();
          _selectedProductId = validDropdownValue(_selectedProductId, productIds) ??
              (productIds.isNotEmpty ? productIds.first : null);
          final product = _selectedProduct(products);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ScreenPageLayout(
                  maxWidth: kFormMaxWidth,
                  header: StatusChipHeader(
                    chips: [
                      StatusChipData(
                        icon: Icons.today_outlined,
                        label: todayAsync.valueOrNull != null
                            ? 'Hoje: ${todayAsync.value!.total} testes'
                            : 'Turno',
                        color: DipontoColors.primary,
                      ),
                      if (deviceId != null)
                        StatusChipData(
                          icon: device?.isOnline == true ? Icons.wifi : Icons.wifi_off,
                          label: demoMode && deviceId == kDemoDeviceId
                              ? 'Bancada demo'
                              : formatBancadaLabelFromMap(deviceId, bancadas),
                          color: device?.isOnline == true
                              ? DipontoColors.success
                              : DipontoColors.error,
                        ),
                      if (demoMode)
                        const StatusChipData(
                          icon: Icons.smart_display_outlined,
                          label: 'Demonstração',
                          color: Colors.deepPurpleAccent,
                        ),
                      if (activeBatch != null)
                        StatusChipData(
                          icon: Icons.playlist_add_check,
                          label: 'OP ${activeBatch.numeroOp}',
                          color: DipontoColors.primaryLight,
                        ),
                    ],
                  ),
                  intro: const SectionIntro(
                    title: 'Iniciar lote',
                    subtitle: 'Escolha o produto, digite a OP e aperte Iniciar lote.',
                    icon: Icons.playlist_add_check,
                  ),
                  children: [
                    if (!bancadaReady || deviceId == null)
                      ActionSectionCard(
                        icon: Icons.link_off,
                        title: 'Bancada não pronta',
                        subtitle: 'É preciso configurar o posto',
                        accentColor: Colors.orangeAccent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Nenhuma bancada vinculada. Peça ajuda ao gestor ou configure agora.',
                              style: TextStyle(color: Colors.orangeAccent),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _openPostoSetup,
                              child: const Text('Configurar bancada'),
                            ),
                          ],
                        ),
                      )
                    else
                      ActionSectionCard(
                        icon: Icons.play_circle_outline,
                        title: 'Lote',
                        subtitle: device?.isOnline == true
                            ? '${formatBancadaLabelFromMap(deviceId, bancadas)} · conectada'
                            : '${formatBancadaLabelFromMap(deviceId, bancadas)} · offline',
                        accentColor: device?.isOnline == true
                            ? DipontoColors.success
                            : DipontoColors.error,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (activeBatch != null) ...[
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.play_circle_outline,
                                    color: DipontoColors.primary,
                                  ),
                                  title: const Text('Lote em andamento'),
                                  subtitle: Text(
                                    'OP ${activeBatch.numeroOp} — toque para continuar',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openLiveDashboard(
                                    deviceId,
                                    activeBatch.numeroOp,
                                  ),
                                ),
                                const Divider(),
                              ],
                              DropdownButtonFormField<String>(
                                value: _selectedProductId,
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
                                Text(
                                  'Teste ${product.tempoTesteSec} s · '
                                  '${product.potenciaMin.toStringAsFixed(1)}–'
                                  '${product.potenciaMax.toStringAsFixed(1)} W',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: DipontoColors.primaryLight,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              ResponsiveFieldRow(
                                flexes: const [2, 1],
                                children: [
                                  TextFormField(
                                    controller: _numeroOp,
                                    decoration:
                                        const InputDecoration(labelText: 'Número OP'),
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Obrigatório' : null,
                                  ),
                                  TextFormField(
                                    controller: _quantidadeTotal,
                                    decoration:
                                        const InputDecoration(labelText: 'Quantidade'),
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Informe a quantidade';
                                      }
                                      final n = int.tryParse(v.trim());
                                      if (n == null || n < 1) {
                                        return 'Mínimo 1';
                                      }
                                      if (n > 100000) {
                                        return 'Valor muito alto';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _openSettings,
                                  child: const Text('Alterar bancada…'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildBottomBar(
                product: product,
                bancadaReady: bancadaReady,
                deviceId: deviceId,
                activeBatch: activeBatch,
              ),
            ],
          );
        },
      ),
    );
  }
}
