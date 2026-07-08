import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/demo_mode_banner.dart';
import '../../shared/widgets/rejection_labels.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/screen_page_layout.dart';
import '../../shared/widgets/section_intro.dart';
import '../../shared/widgets/status_chip_header.dart';
import '../bancadas/bancadas_provider.dart';
import '../cloud/auth/auth_providers.dart';
import '../demo/demo_live_controls.dart';
import '../demo/demo_playback.dart';
import '../demo/demo_providers.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../operators/operators_provider.dart';
import '../products/products_provider.dart';
import 'batch_live_providers.dart';
import 'batch_live_widgets.dart';

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

  @override
  void deactivate() {
    try {
      ref.read(demoPlaybackProvider).stop();
    } on StateError {
      // Container descartado (ex.: tearDown de teste).
    }
    super.deactivate();
  }

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
    final metricsAsync = ref.watch(batchLiveMetricsProvider(widget.numeroOp));
    final labelCountAsync = ref.watch(labelBufferCountProvider);
    final retestMode = ref.watch(retestModeProvider);
    final activeOp = ref.watch(activeOperatorProvider).valueOrNull;
    final operador = activeOp != null
        ? AppDatabase.operatorLabel(activeOp)
        : (ref.watch(authStateProvider).valueOrNull?.email ?? 'Operação local');
    final productsAsync = ref.watch(productsStreamProvider);
    final bancadaLabel = formatBancadaLabelFromMap(widget.deviceId, bancadas);

    ref.listen(latestRejectionProvider, (prev, next) {
      if (next != null && next.deviceId == widget.deviceId) {
        _showSnack('Rejeição: ${formatRejectionMotivo(next.rejection.motivo)}');
      }
    });

    ref.listen(latestNvsFaultProvider, (prev, next) {
      if (next != null && next.deviceId == widget.deviceId) {
        _showSnack(
          'Alerta: ${next.alert.detalhe ?? formatRejectionMotivo(next.alert.evento)}',
        );
      }
    });

    ref.listen(duplicateSerialProvider, (prev, next) {
      if (next != null && next.deviceId == widget.deviceId) {
        _showSnack('Serial duplicado ${next.serial} — etiqueta não emitida');
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

    final meta = batch?.quantidadeTotal ?? 0;
    final metrics = metricsAsync.valueOrNull;
    final labelCount = labelCountAsync.valueOrNull ?? 0;
    final demoMode = ref.watch(demoModeProvider);
    final isGestor = ref.watch(activeOperatorIsGestorProvider);

    final chips = isGestor
        ? <StatusChipData>[
            StatusChipData(
              icon: Icons.tag,
              label: 'OP ${widget.numeroOp}',
              color: DipontoColors.primary,
            ),
            StatusChipData(
              icon: device?.isOnline == true ? Icons.wifi : Icons.wifi_off,
              label: bancadaLabel,
              color: device?.isOnline == true ? DipontoColors.success : DipontoColors.error,
            ),
            StatusChipData(
              icon: estado == DeviceFsmState.testing ? Icons.hourglass_top : Icons.play_circle_outline,
              label: estado.label,
              color: estado == DeviceFsmState.testing ? DipontoColors.primaryLight : DipontoColors.primary,
            ),
            if (meta > 0 && metrics != null)
              StatusChipData(
                icon: Icons.check_circle_outline,
                label: '${metrics.aprovados}/$meta',
                color: DipontoColors.success,
              ),
            if (labelCount > 0)
              StatusChipData(
                icon: Icons.label_outline,
                label: '$labelCount etiqueta(s)',
                color: DipontoColors.primaryLight,
              ),
            if (demoMode)
              const StatusChipData(
                icon: Icons.smart_display_outlined,
                label: 'Demonstração',
                color: Colors.deepPurpleAccent,
              ),
          ]
        : <StatusChipData>[
            StatusChipData(
              icon: Icons.tag,
              label: 'OP ${widget.numeroOp}',
              color: DipontoColors.primary,
            ),
            StatusChipData(
              icon: device?.isOnline == true ? Icons.wifi : Icons.wifi_off,
              label: bancadaLabel,
              color: device?.isOnline == true ? DipontoColors.success : DipontoColors.error,
            ),
            if (meta > 0 && metrics != null)
              StatusChipData(
                icon: Icons.check_circle_outline,
                label: '${metrics.aprovados}/$meta',
                color: DipontoColors.success,
              ),
          ];

    final introSubtitle = [
      if (productName != null) productName,
      operador,
      if (batch != null)
        '${batch.potenciaMin.toStringAsFixed(1)}–${batch.potenciaMax.toStringAsFixed(1)} W',
    ].join(' · ');

    return Scaffold(
      appBar: screenAppBar(context, title: 'OP ${widget.numeroOp}'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ScreenPageLayout(
              maxWidth: 900,
              header: StatusChipHeader(chips: chips),
              intro: SectionIntro(
                title: isGestor ? 'Painel ao vivo' : 'Teste',
                subtitle: isGestor ? introSubtitle : (productName ?? operador),
                icon: isGestor ? Icons.monitor_heart_outlined : Icons.play_circle_outline,
              ),
              children: [
                if (demoMode && isGestor) const DemoModeBanner(compact: true),
                if (isGestor) ...[
                  if (device?.lastNvsFault != null)
                    _NvsFaultBanner(alert: device!.lastNvsFault!),
                  if (device?.lastRejection != null)
                    _RejectionBanner(motivo: device!.lastRejection!.motivo),
                ] else ...[
                  if (device?.lastNvsFault != null)
                    BatchLiveOperatorAlert(
                      isError: false,
                      message: device!.lastNvsFault!.detalhe ??
                          formatRejectionMotivo(device!.lastNvsFault!.evento),
                    ),
                  if (device?.lastRejection != null)
                    BatchLiveOperatorAlert(
                      message: formatRejectionMotivo(device!.lastRejection!.motivo),
                    ),
                ],
                _BatchLiveBody(
                  deviceId: widget.deviceId,
                  numeroOp: widget.numeroOp,
                  device: device,
                  estado: estado,
                  batch: batch,
                  productName: productName,
                  bancadaLabel: bancadaLabel,
                  operador: operador,
                  retestMode: retestMode,
                  syncingRetest: _syncingRetest,
                  onRetestChanged: _toggleRetest,
                  onSimulateOnce: _simulateTest,
                  simulating: _simulating,
                  isGestor: isGestor,
                ),
              ],
            ),
          ),
          ScreenBottomBar(
            hint: meta > 0 && metrics != null
                ? '${metrics.aprovados} de $meta aprovados'
                : null,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
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
          ),
        ],
      ),
    );
  }
}

/// Corpo com um único watch de testes para hero, gráfico e lista.
class _BatchLiveBody extends ConsumerWidget {
  const _BatchLiveBody({
    required this.deviceId,
    required this.numeroOp,
    required this.device,
    required this.estado,
    required this.batch,
    required this.productName,
    required this.bancadaLabel,
    required this.operador,
    required this.retestMode,
    required this.syncingRetest,
    required this.onRetestChanged,
    required this.onSimulateOnce,
    required this.simulating,
    required this.isGestor,
  });

  final String deviceId;
  final String numeroOp;
  final DeviceInfo? device;
  final DeviceFsmState estado;
  final BatchConfig? batch;
  final String? productName;
  final String bancadaLabel;
  final String operador;
  final bool retestMode;
  final bool syncingRetest;
  final ValueChanged<bool> onRetestChanged;
  final VoidCallback onSimulateOnce;
  final bool simulating;
  final bool isGestor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(batchLiveTestsProvider(numeroOp));
    final metricsAsync = ref.watch(batchLiveMetricsProvider(numeroOp));
    final mqttState = resolveMqttConnectionDisplayState(
      ref.watch(mqttConnectionStateProvider),
      ref.read(mqttServiceProvider).currentState,
    );
    final mqttDisconnected = mqttState != AppMqttConnectionState.connected;

    return testsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Erro ao carregar testes: $e'),
      data: (tests) {
        final liveResult = device?.lastTestResult?.numeroOp == numeroOp
            ? device?.lastTestResult
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isGestor) ...[
              BatchLiveLastTestHero(
                estado: estado,
                tests: tests,
                liveResult: liveResult,
                potenciaMin: batch?.potenciaMin,
                potenciaMax: batch?.potenciaMax,
                mqttDisconnected: mqttDisconnected,
              ),
              DemoLiveControls(
                deviceId: deviceId,
                hasActiveBatch: batch != null,
                onSimulateOnce: onSimulateOnce,
                simulating: simulating,
              ),
              metricsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Erro nas métricas: $e'),
                data: (metrics) => BatchLiveProgressSection(
                  metrics: metrics,
                  meta: batch?.quantidadeTotal ?? 0,
                ),
              ),
              if (batch != null)
                ActionSectionCard(
                  icon: Icons.replay_outlined,
                  title: 'Reteste',
                  subtitle: retestMode
                      ? 'Ativo — testes não consomem serial nem cota'
                      : 'Repetir teste sem gerar serial',
                  accentColor: retestMode ? Colors.lightBlueAccent : DipontoColors.onSurface.withValues(alpha: 0.4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modo reteste',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'Não gera serial nem consome meta do lote',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DipontoColors.onSurface.withValues(alpha: 0.65),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (syncingRetest)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Switch(
                          value: retestMode,
                          onChanged: estado == DeviceFsmState.testing || syncingRetest
                              ? null
                              : onRetestChanged,
                        ),
                    ],
                  ),
                ),
              BatchLivePowerChart(
                tests: tests,
                potenciaMin: batch?.potenciaMin,
                potenciaMax: batch?.potenciaMax,
              ),
              BatchLiveRecentTests(
                tests: tests,
                onViewAll: tests.length > 10
                    ? () => showBatchHistorySheet(context, tests)
                    : null,
              ),
              BatchLiveDetailsExpansion(
                numeroOp: numeroOp,
                productName: productName,
                bancadaLabel: bancadaLabel,
                operador: operador,
                estado: estado,
                batch: batch,
                tests: tests,
              ),
            ] else ...[
              BatchLiveOperatorHero(
                estado: estado,
                tests: tests,
                numeroOp: numeroOp,
                productName: productName,
                liveResult: liveResult,
                potenciaMin: batch?.potenciaMin,
                potenciaMax: batch?.potenciaMax,
                mqttDisconnected: mqttDisconnected,
                filaOffline: device?.fila ?? 0,
              ),
              const SizedBox(height: 16),
              metricsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (metrics) => BatchLiveOperatorProgress(
                  metrics: metrics,
                  meta: batch?.quantidadeTotal ?? 0,
                ),
              ),
              const SizedBox(height: 12),
              BatchLiveOperatorStatusStrip(
                bancadaLabel: bancadaLabel,
                estado: estado,
                mqttDisconnected: mqttDisconnected,
                filaOffline: device?.fila ?? 0,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({required this.motivo});

  final String motivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DipontoColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DipontoColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: DipontoColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Última rejeição MQTT', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(formatRejectionMotivo(motivo)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NvsFaultBanner extends StatelessWidget {
  const _NvsFaultBanner({required this.alert});

  final NvsFaultAlertMessage alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storage_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Falha de memória do lote (NVS)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  alert.detalhe ?? formatRejectionMotivo(alert.evento),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
