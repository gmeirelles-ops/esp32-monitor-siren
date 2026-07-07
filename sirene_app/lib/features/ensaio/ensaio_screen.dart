import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/screen_page_layout.dart';
import '../../shared/widgets/section_intro.dart';
import '../../shared/widgets/status_chip_header.dart';
import '../bancadas/bancadas_provider.dart';
import '../demo/demo_constants.dart';
import '../demo/demo_providers.dart';
import '../demo/demo_service.dart';
import '../mqtt/mqtt_providers.dart';
import '../setup/posto_setup_screen.dart';
import 'ensaio_pdf_export.dart';
import 'ensaio_providers.dart';

class EnsaioScreen extends ConsumerStatefulWidget {
  const EnsaioScreen({super.key});

  @override
  ConsumerState<EnsaioScreen> createState() => _EnsaioScreenState();
}

class _EnsaioScreenState extends ConsumerState<EnsaioScreen> {
  final _nome = TextEditingController();
  final _onMin = TextEditingController(text: '${EnsaioConfig.defaults.onMinutes}');
  final _offMin = TextEditingController(text: '${EnsaioConfig.defaults.offMinutes}');
  final _totalMin = TextEditingController(text: '${EnsaioConfig.defaults.totalMinutes}');
  final _historyQuery = TextEditingController();

  bool _starting = false;
  bool _stopping = false;
  bool _showAllHistory = false;

  @override
  void dispose() {
    _nome.dispose();
    _onMin.dispose();
    _offMin.dispose();
    _totalMin.dispose();
    _historyQuery.dispose();
    super.dispose();
  }

  EnsaioConfig? _readConfig() {
    final onMin = int.tryParse(_onMin.text.trim());
    final offMin = int.tryParse(_offMin.text.trim());
    final totalMin = int.tryParse(_totalMin.text.trim());
    if (onMin == null || offMin == null || totalMin == null) return null;
    if (onMin <= 0 || offMin <= 0 || totalMin <= 0) return null;
    return EnsaioConfig(
      onSeconds: onMin * 60,
      offSeconds: offMin * 60,
      totalSeconds: totalMin * 60,
    );
  }

  void _applyPreset(int onMin, int offMin, int totalMin) {
    setState(() {
      _onMin.text = '$onMin';
      _offMin.text = '$offMin';
      _totalMin.text = '$totalMin';
    });
  }

  Future<void> _start() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      _snack('Informe um nome para o ensaio');
      return;
    }

    final config = _readConfig();
    if (config == null) {
      _snack('Preencha os tempos corretamente');
      return;
    }
    final validation = config.validate();
    if (validation != null) {
      _snack(validation);
      return;
    }

    final deviceId = resolveActiveDeviceId(ref);
    if (deviceId == null) {
      _snack('Nenhuma bancada vinculada');
      return;
    }

    setState(() => _starting = true);
    try {
      final error = await ref.read(ensaioControllerProvider).start(deviceId, nome, config);
      if (!mounted) return;
      if (error != null) {
        _snack(error == 'nome_obrigatorio'
            ? 'Informe um nome para o ensaio'
            : 'Não foi possível iniciar: $error');
      } else {
        ref.read(ensaioConfigProvider.notifier).state = config;
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    final session = ref.read(ensaioSessionProvider);
    if (session == null) return;

    setState(() => _stopping = true);
    try {
      final error = await ref.read(ensaioControllerProvider).stop(session.deviceId);
      if (!mounted) return;
      if (error != null) {
        _snack('Erro ao parar: $error');
      }
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openPostoSetup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PostoSetupScreen()),
    );
  }

  Future<void> _openPdf(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) {
      _snack('Arquivo PDF não encontrado');
      return;
    }
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(ensaioSessionProvider);
    final history = ref.watch(ensaioHistoryProvider);
    final demoMode = ref.watch(demoModeProvider);
    final devices = ref.watch(devicesProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final deviceId = resolveActiveDeviceId(ref);
    final device = deviceId != null ? devices[deviceId] : null;
    final running = session?.isActive ?? false;

    ref.listen(ensaioSessionProvider, (prev, next) {
      if (prev?.isActive == true && next != null && !next.isActive) {
        final msg = next.phase == EnsaioPhase.completed
            ? 'Ensaio concluído'
            : 'Ensaio interrompido';
        _snack(msg);
      }
    });

    ref.listen(ensaioPdfSavedProvider, (prev, next) {
      if (next != null && next.isNotEmpty) {
        _snack('PDF salvo: $next');
      }
    });

    ref.listen(ensaioRemoteStatusProvider, (prev, next) {
      if (next == null) return;
      final config = ref.read(ensaioConfigProvider);
      ref.read(ensaioControllerProvider).applyRemoteStatus(
            next.deviceId,
            next.msg,
            config,
          );
    });

    if (deviceId == null && !demoMode) {
      return Scaffold(
        appBar: screenAppBar(context, title: 'Ensaio'),
        body: const EmptyStateView(
          icon: Icons.link_off,
          title: 'Bancada não vinculada',
          subtitle: 'Configure o posto antes de usar o modo ensaio.',
        ),
      );
    }

    return Scaffold(
      appBar: screenAppBar(context, title: 'Ensaio'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ScreenPageLayout(
              header: StatusChipHeader(
                chips: [
                  if (deviceId != null)
                    StatusChipData(
                      icon: device?.isOnline == true ? Icons.wifi : Icons.wifi_off,
                      label: demoMode && deviceId == kDemoDeviceId
                          ? 'Bancada demo'
                          : formatBancadaLabelFromMap(deviceId, bancadas),
                      color: device?.isOnline == true ? DipontoColors.success : DipontoColors.error,
                    ),
                  if (running)
                    StatusChipData(
                      icon: session!.phase == EnsaioPhase.on
                          ? Icons.power
                          : Icons.power_off,
                      label: session.phaseLabel,
                      color: session.phase == EnsaioPhase.on
                          ? Colors.amberAccent
                          : DipontoColors.onSurface.withValues(alpha: 0.5),
                    ),
                  if (session != null && session.cycle > 0)
                    StatusChipData(
                      icon: Icons.repeat,
                      label: 'Ciclo ${session.cycle}',
                      color: DipontoColors.primaryLight,
                    ),
                ],
              ),
              intro: const SectionIntro(
                title: 'Modo ensaio',
                subtitle:
                    'Alterna a sirene ligada e desligada por um período total — útil para testes de resistência.',
                icon: Icons.science_outlined,
              ),
              children: [
                if (session != null && (session.isActive || session.phase == EnsaioPhase.completed))
                  _EnsaioLiveCard(session: session),
                if (!running) ...[
                  ActionSectionCard(
                    icon: Icons.badge_outlined,
                    title: 'Identificação',
                    subtitle: 'Nome obrigatório — aparece no PDF do relatório',
                    child: TextField(
                      controller: _nome,
                      decoration: const InputDecoration(
                        labelText: 'Nome do ensaio',
                        hintText: 'Ex.: Resistência lote março',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  ActionSectionCard(
                    icon: Icons.tune,
                    title: 'Ciclo',
                    subtitle: 'Tempos de cada fase e duração total',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('1 / 1 / 120 min'),
                              onPressed: () => _applyPreset(1, 1, 120),
                            ),
                            ActionChip(
                              label: const Text('2 / 1 / 240 min'),
                              onPressed: () => _applyPreset(2, 1, 240),
                            ),
                            ActionChip(
                              label: const Text('5 / 2 / 120 min'),
                              onPressed: () => _applyPreset(5, 2, 120),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _onMin,
                                decoration: const InputDecoration(
                                  labelText: 'Ligado',
                                  suffixText: 'min',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _offMin,
                                decoration: const InputDecoration(
                                  labelText: 'Desligado',
                                  suffixText: 'min',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _totalMin,
                          decoration: const InputDecoration(
                            labelText: 'Duração total',
                            suffixText: 'min',
                            helperText: 'Tempo total do ensaio em minutos',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final cfg = _readConfig();
                            if (cfg == null) return const SizedBox.shrink();
                            return Text(
                              'Ciclo: ${cfg.onMinutes} + ${cfg.offMinutes} min · '
                              'total ${cfg.totalMinutes} min',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DipontoColors.primaryLight,
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (deviceId == null)
                    ActionSectionCard(
                      icon: Icons.link_off,
                      title: 'Bancada',
                      subtitle: 'Configure o posto',
                      accentColor: Colors.orangeAccent,
                      child: FilledButton(
                        onPressed: _openPostoSetup,
                        child: const Text('Configurar bancada'),
                      ),
                    ),
                ],
                ActionSectionCard(
                  icon: Icons.history,
                  title: 'Histórico',
                  subtitle: 'Ensaios salvos com relatório PDF',
                  child: history.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Erro: $e'),
                    data: (records) {
                      if (records.isEmpty) {
                        return Text(
                          'Nenhum ensaio registrado ainda.',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
                      final query = _historyQuery.text.trim().toLowerCase();
                      final filtered = records.where((r) {
                        if (query.isEmpty) return true;
                        return r.nome.toLowerCase().contains(query) ||
                            ensaioStatusLabel(r.status).toLowerCase().contains(query);
                      }).toList();
                      final visible = _showAllHistory ? filtered : filtered.take(15).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _historyQuery,
                            decoration: const InputDecoration(
                              labelText: 'Buscar ensaio',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          if (filtered.length > 15)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => setState(() => _showAllHistory = !_showAllHistory),
                                child: Text(
                                  _showAllHistory
                                      ? 'Mostrar menos'
                                      : 'Ver todos (${filtered.length})',
                                ),
                              ),
                            ),
                          for (final r in visible)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                r.pdfPath != null ? Icons.picture_as_pdf : Icons.science_outlined,
                                color: DipontoColors.primary,
                              ),
                              title: Text(r.nome),
                              subtitle: Text(
                                '${ensaioStatusLabel(r.status)} · '
                                '${dateFmt.format(r.startedAt.toLocal())}',
                              ),
                              trailing: r.pdfPath != null
                                  ? IconButton(
                                      tooltip: 'Abrir PDF',
                                      icon: const Icon(Icons.open_in_new),
                                      onPressed: () => _openPdf(r.pdfPath),
                                    )
                                  : null,
                              onTap: r.pdfPath != null ? () => _openPdf(r.pdfPath) : null,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ScreenBottomBar(
            hint: session != null && session.isActive
                ? 'Restam ${formatEnsaioDuration(session.remainingSeconds)}'
                : null,
            child: running
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DipontoColors.error,
                      side: const BorderSide(color: DipontoColors.error),
                    ),
                    onPressed: _stopping ? null : _stop,
                    icon: _stopping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.stop),
                    label: const Text('Parar ensaio'),
                  )
                : FilledButton.icon(
                    onPressed: _starting || deviceId == null ? null : _start,
                    icon: _starting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Iniciar ensaio'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EnsaioLiveCard extends StatelessWidget {
  const _EnsaioLiveCard({required this.session});

  final EnsaioSession session;

  @override
  Widget build(BuildContext context) {
    final onPhase = session.phase == EnsaioPhase.on;
    final accent = onPhase ? Colors.amberAccent : DipontoColors.onSurface.withValues(alpha: 0.4);

    return ActionSectionCard(
      icon: onPhase ? Icons.bolt : Icons.nightlight_outlined,
      title: session.isActive ? session.phaseLabel : session.phaseLabel,
      subtitle: session.isActive
          ? 'Ciclo ${session.cycle} · ${formatEnsaioDuration(session.remainingSeconds)} restantes'
          : 'Ensaio finalizado',
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Semantics(
              label: 'Progresso do ensaio ${(session.progress * 100).toStringAsFixed(0)} por cento',
              child: LinearProgressIndicator(
                value: session.progress,
                minHeight: 10,
                backgroundColor: DipontoColors.surfaceVariant,
                color: onPhase ? Colors.amberAccent : DipontoColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Kpi('Ligado', '${session.config.onMinutes} min'),
              _Kpi('Desligado', '${session.config.offMinutes} min'),
              _Kpi('Total', '${session.config.totalMinutes} min'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: DipontoColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
