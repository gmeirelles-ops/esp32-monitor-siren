import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/database/veredito.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/global_app_bar_actions.dart';
import '../../shared/widgets/simple_bar_chart.dart';
import '../bancadas/bancadas_provider.dart';
import '../cloud/auth/auth_providers.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../operators/operators_provider.dart';
import '../products/products_provider.dart';
import 'batch_live_providers.dart';

class BatchLiveScreen extends ConsumerStatefulWidget {
  const BatchLiveScreen({
    required this.deviceId,
    required this.numeroOp,
    super.key,
  });

  final String deviceId;
  final String numeroOp;

  @override
  ConsumerState<BatchLiveScreen> createState() => _BatchLiveScreenState();
}

class _BatchLiveScreenState extends ConsumerState<BatchLiveScreen> {
  bool _ending = false;
  bool _simulating = false;
  bool _syncingRetest = false;

  Future<void> _endBatch() async {
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
    if (confirm != true || !mounted) return;

    setState(() => _ending = true);
    try {
      final rejection = await ref.read(devicesProvider.notifier).sendEndBatch(widget.deviceId);
      if (!mounted) return;
      if (rejection != null) {
        _showSnack('Comando rejeitado: $rejection');
      } else {
        _showSnack('Lote encerrado');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnack('Erro: $e');
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  Future<void> _simulateTest() async {
    setState(() => _simulating = true);
    try {
      await ref.read(devicesProvider.notifier).simulateTestResult(widget.deviceId);
      if (!mounted) return;
      _showSnack('Teste simulado registrado');
    } catch (e) {
      _showSnack('Erro: $e');
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggleRetest(bool value) async {
    setState(() => _syncingRetest = true);
    try {
      final rejection =
          await ref.read(devicesProvider.notifier).syncRetestMode(widget.deviceId, value);
      if (!mounted) return;
      if (rejection != null) {
        _showSnack('Não foi possível alterar reteste: $rejection');
      }
    } catch (e) {
      _showSnack('Erro: $e');
    } finally {
      if (mounted) setState(() => _syncingRetest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(devicesProvider)[widget.deviceId];
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final batch = device?.activeBatch;
    final estado = device?.estado ?? DeviceFsmState.unknown;
    final testsAsync = ref.watch(batchLiveTestsProvider(widget.numeroOp));
    final metricsAsync = ref.watch(batchLiveMetricsProvider(widget.numeroOp));
    final labelCountAsync = ref.watch(labelBufferCountProvider);
    final devUsed = ref.watch(batchDevSimulatorUsedProvider);
    final retestMode = ref.watch(retestModeProvider);
    final activeOp = ref.watch(activeOperatorProvider).valueOrNull;
    final operador = activeOp != null
        ? AppDatabase.operatorLabel(activeOp)
        : (ref.watch(authStateProvider).valueOrNull?.email ?? 'Operação local');
    final dateFmt = DateFormat('HH:mm:ss');
    final productsAsync = ref.watch(productsStreamProvider);

    ref.listen(latestRejectionProvider, (prev, next) {
      if (next != null && next.deviceId == widget.deviceId) {
        _showSnack('Rejeição: ${next.rejection.motivo}');
      }
    });

    ref.listen(autoBatchEndedProvider, (prev, next) {
      if (next != null &&
          next.deviceId == widget.deviceId &&
          next.numeroOp == widget.numeroOp &&
          mounted) {
        _showSnack('Lote encerrado automaticamente — meta atingida');
        Navigator.of(context).pop();
        ref.read(autoBatchEndedProvider.notifier).state = null;
      }
    });

    final productName = productsAsync.maybeWhen(
      data: (products) {
        final id = batch?.idProduto;
        if (id == null) return id;
        for (final p in products) {
          if (p.idProduto == id) return '${p.idProduto} — ${p.nome}';
        }
        return id;
      },
      orElse: () => batch?.idProduto,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Lote ${widget.numeroOp}'),
        actions: globalAppBarActions(),
      ),
      body: ListView(
        children: [
          DesktopFormLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kDebugMode || devUsed)
                  Card(
                    color: Colors.orange.withValues(alpha: 0.15),
                    child: const ListTile(
                      leading: Icon(Icons.science_outlined, color: Colors.orangeAccent),
                      title: Text('MODO DEV — simulação disponível'),
                      subtitle: Text('Testes simulados usam potências fictícias'),
                    ),
                  ),
                if (retestMode)
                  Card(
                    color: Colors.blue.withValues(alpha: 0.12),
                    child: const ListTile(
                      leading: Icon(Icons.replay, color: Colors.lightBlueAccent),
                      title: Text('Modo reteste'),
                      subtitle: Text('Testes não consomem serial nem cota do lote'),
                    ),
                  ),
                if (batch != null)
                  Card(
                    child: CheckboxListTile(
                      value: retestMode,
                      onChanged: estado == DeviceFsmState.testing || _syncingRetest
                          ? null
                          : (v) => _toggleRetest(v ?? false),
                      title: const Text('Reteste'),
                      subtitle: const Text(
                        'Repetir teste sem gerar serial nem consumir meta',
                      ),
                      secondary: _syncingRetest
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.replay_outlined),
                    ),
                  ),
                FormSectionCard(
                  title: 'Contexto',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('OP', widget.numeroOp),
                      _InfoRow('Produto', productName ?? '—'),
                      _InfoRow(
                        'Bancada',
                        formatBancadaLabelFromMap(widget.deviceId, bancadas),
                      ),
                      _InfoRow('Operador', operador),
                      _InfoRow('Estado', estado.label),
                      if (batch != null) ...[
                        _InfoRow(
                          'Potência',
                          '${batch.potenciaMin.toStringAsFixed(1)}–${batch.potenciaMax.toStringAsFixed(1)} W',
                        ),
                        _InfoRow('Meta', '${batch.quantidadeTotal} peças'),
                      ],
                    ],
                  ),
                ),
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
                metricsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Erro nas métricas: $e'),
                  data: (metrics) {
                    final meta = batch?.quantidadeTotal ?? 0;
                    final progress = meta > 0
                        ? (metrics.aprovados / meta).clamp(0.0, 1.0)
                        : 0.0;
                    return FormSectionCard(
                      title: 'Progresso',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _MetricChip(
                                label: 'Aprovados',
                                value: '${metrics.aprovados}',
                                color: DipontoColors.success,
                              ),
                              _MetricChip(
                                label: 'Reprovados',
                                value: '${metrics.reprovados}',
                                color: DipontoColors.error,
                              ),
                              _MetricChip(
                                label: PortugueseLabels.totalTestadas,
                                value: '${metrics.total}',
                              ),
                              _MetricChip(
                                label: PortugueseLabels.rendimento,
                                value: '${metrics.yieldPct.toStringAsFixed(1)}%',
                                color: DipontoColors.primaryLight,
                              ),
                              if (meta > 0)
                                _MetricChip(
                                  label: 'Pendentes',
                                  value: '${metrics.pendentes(meta)}',
                                ),
                            ],
                          ),
                          if (meta > 0) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              color: DipontoColors.primary,
                              backgroundColor: DipontoColors.surfaceVariant,
                            ),
                            Text('${metrics.aprovados} / $meta aprovados'),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                labelCountAsync.when(
                  data: (count) {
                    if (count == 0) return const SizedBox.shrink();
                    return Card(
                      color: DipontoColors.primary.withValues(alpha: 0.1),
                      child: ListTile(
                        leading: const Icon(Icons.label_outline, color: DipontoColors.primary),
                        title: Text('$count etiqueta(s) na fila de impressão'),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                testsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (tests) {
                    final seriais = [
                      for (final t in tests)
                        if (t.serial != null) t.serial!,
                    ];
                    if (seriais.isEmpty) return const SizedBox.shrink();
                    return FormSectionCard(
                      title: 'Seriais emitidos',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final serial in seriais)
                            Chip(
                              avatar: const Icon(Icons.qr_code_2, size: 18),
                              label: Text(serial),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (device?.lastRejection != null)
                  Card(
                    color: DipontoColors.error.withValues(alpha: 0.12),
                    child: ListTile(
                      leading: const Icon(Icons.error_outline, color: DipontoColors.error),
                      title: const Text('Última rejeição MQTT'),
                      subtitle: Text(device!.lastRejection!.motivo),
                    ),
                  ),
                testsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Erro no histórico: $e'),
                  data: (tests) {
                    if (tests.isEmpty) {
                      return const FormSectionCard(
                        title: 'Potência por teste',
                        child: Text(
                          'Nenhum teste registrado nesta OP. '
                          'Pressione o botão no dispositivo ou use o simulador (dev).',
                        ),
                      );
                    }
                    final chartTests = tests.take(50).toList().reversed.toList();
                    final bars = [
                      for (final t in chartTests)
                        SimpleBarChartBar(
                          label: t.sequencial.toString(),
                          value: t.potenciaMedia,
                          color: isApprovedVeredito(t.veredito)
                              ? DipontoColors.success
                              : DipontoColors.error,
                        ),
                    ];
                    return FormSectionCard(
                      title: 'Potência por teste (últimos ${chartTests.length})',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (batch != null)
                            Text(
                              'Faixa aceitável: ${batch.potenciaMin.toStringAsFixed(1)}–'
                              '${batch.potenciaMax.toStringAsFixed(1)} W',
                              style: TextStyle(
                                color: DipontoColors.onSurface.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          SimpleBarChart(bars: bars, height: 180),
                        ],
                      ),
                    );
                  },
                ),
                testsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (tests) => FormSectionCard(
                    title: 'Histórico do lote',
                    child: tests.isEmpty
                        ? const Text('Sem testes ainda.')
                        : Column(
                            children: [
                              for (final t in tests)
                                Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  color: isApprovedVeredito(t.veredito)
                                      ? DipontoColors.success.withValues(alpha: 0.1)
                                      : DipontoColors.error.withValues(alpha: 0.1),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      '${t.veredito} — ${t.potenciaMedia.toStringAsFixed(2)} W',
                                    ),
                                    subtitle: Text(
                                      'Seq ${t.sequencial}'
                                      '${t.serial != null ? ' · ${t.serial}' : ''}'
                                      '${t.operador != null ? '\n${t.operador}' : ''}'
                                      '\n${dateFmt.format(t.createdAt.toLocal())}',
                                    ),
                                    isThreeLine: true,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (kDebugMode)
                      OutlinedButton.icon(
                        onPressed: _simulating || batch == null ? null : _simulateTest,
                        icon: _simulating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.science_outlined),
                        label: const Text('Simular teste (dev)'),
                      ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DipontoColors.error,
                        side: const BorderSide(color: DipontoColors.error),
                      ),
                      onPressed: _ending ? null : _endBatch,
                      child: _ending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(PortugueseLabels.encerrarLote),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DipontoColors.cardElevated,
        borderRadius: BorderRadius.circular(10),
        border: color != null ? Border.all(color: color!.withValues(alpha: 0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: DipontoColors.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
