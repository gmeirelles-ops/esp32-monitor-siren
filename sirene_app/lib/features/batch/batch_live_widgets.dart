import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/batch_metrics.dart';
import '../../core/database/database.dart';
import '../../core/database/veredito.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/rejection_labels.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/simple_bar_chart.dart';
import '../labels/laser_mark_callout.dart';
import '../labels/manual_serial_dialog.dart';
import '../labels/mark_queue_ui.dart';
import '../labels/marking_providers.dart';
import '../mqtt/models/mqtt_messages.dart';
import 'batch_live_providers.dart';

/// Cartão hero: estado FSM + último resultado do teste.
class BatchLiveLastTestHero extends StatelessWidget {
  const BatchLiveLastTestHero({
    super.key,
    required this.estado,
    required this.tests,
    this.liveResult,
    this.potenciaMin,
    this.potenciaMax,
    this.mqttDisconnected = false,
  });

  final DeviceFsmState estado;
  final List<TestResult> tests;
  final TestResultMessage? liveResult;
  final double? potenciaMin;
  final double? potenciaMax;
  final bool mqttDisconnected;

  @override
  Widget build(BuildContext context) {
    final latest = _resolveLatest();
    if (estado == DeviceFsmState.testing && latest == null && liveResult == null) {
      return _HeroShell(
        accent: DipontoColors.primary,
        icon: Icons.bolt_rounded,
        title: 'Testando',
        subtitle: 'Medindo potência na bancada — aguarde o resultado',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3, color: DipontoColors.primary),
            ),
          ),
        ),
      );
    }

    if (latest == null) {
      return _HeroShell(
        accent: mqttDisconnected ? DipontoColors.error : DipontoColors.primary,
        icon: mqttDisconnected ? Icons.cloud_off : Icons.touch_app,
        title: mqttDisconnected
            ? 'MQTT desconectado'
            : 'Pressione o botão no dispositivo',
        subtitle: mqttDisconnected
            ? 'Testes não chegam até o broker reconectar'
            : estado == DeviceFsmState.batchReady
                ? 'O teste só inicia pelo botão físico da bancada'
                : estado.label,
        child: const SizedBox.shrink(),
      );
    }

    final approved = isApprovedVeredito(latest.veredito);
    final valid = isValidVeredito(latest.veredito);
    final accent = !valid
        ? Colors.orange
        : approved
            ? DipontoColors.success
            : DipontoColors.error;
    final dateFmt = DateFormat('HH:mm:ss');

    return Semantics(
      label: valid
          ? 'Último teste: ${latest.veredito}, ${latest.potenciaMedia.toStringAsFixed(2)} watts'
          : 'Último teste com veredito inválido',
      child: _HeroShell(
        accent: accent,
        icon: !valid
            ? Icons.warning_amber_outlined
            : approved
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
        title: valid ? latest.veredito : 'Veredito inválido',
        subtitle: 'Seq ${latest.sequencial}'
            '${latest.serial != null ? ' · ${latest.serial}' : ''}'
            '${latest.timestamp != null ? ' · ${dateFmt.format(latest.timestamp!.toLocal())}' : ''}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${latest.potenciaMedia.toStringAsFixed(2)} W',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
            ),
            if (potenciaMin != null && potenciaMax != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Faixa: ${potenciaMin!.toStringAsFixed(1)}–${potenciaMax!.toStringAsFixed(1)} W',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DipontoColors.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _LatestDisplay? _resolveLatest() {
    if (liveResult != null) {
      return _LatestDisplay(
        veredito: liveResult!.veredito,
        potenciaMedia: liveResult!.potenciaMedia,
        sequencial: liveResult!.sequencial,
      );
    }
    if (tests.isEmpty) return null;
    final t = tests.first;
    return _LatestDisplay(
      veredito: t.veredito,
      potenciaMedia: t.potenciaMedia,
      sequencial: t.sequencial,
      serial: t.serial,
      timestamp: t.createdAt,
    );
  }
}

class _LatestDisplay {
  const _LatestDisplay({
    required this.veredito,
    required this.potenciaMedia,
    required this.sequencial,
    this.serial,
    this.timestamp,
  });

  final String veredito;
  final double potenciaMedia;
  final int sequencial;
  final String? serial;
  final DateTime? timestamp;
}

class _HeroShell extends StatelessWidget {
  const _HeroShell({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ActionSectionCard(
      icon: icon,
      title: 'Último teste',
      subtitle: subtitle,
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Barra de progresso + 3 KPIs principais.
class BatchLiveProgressSection extends StatelessWidget {
  const BatchLiveProgressSection({
    super.key,
    required this.metrics,
    required this.meta,
  });

  final BatchMetrics metrics;
  final int meta;

  @override
  Widget build(BuildContext context) {
    if (meta <= 0) return const SizedBox.shrink();

    final progress = (metrics.aprovados / meta).clamp(0.0, 1.0);
    final pendentes = metrics.pendentes(meta);
    final percent = (progress * 100).round();

    return ActionSectionCard(
      icon: Icons.trending_up,
      title: 'Progresso do lote',
      subtitle: '$pendentes pendentes · ${metrics.aprovados} aprovados na bancada',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DipontoColors.success.withValues(alpha: 0.14),
                  DipontoColors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DipontoColors.success.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aprovados',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: DipontoColors.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${metrics.aprovados}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: DipontoColors.success,
                                    height: 1,
                                  ),
                            ),
                            TextSpan(
                              text: ' / $meta',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DipontoColors.onSurface.withValues(alpha: 0.75),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DipontoColors.surface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DipontoColors.primaryLight,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              color: DipontoColors.success,
              backgroundColor: DipontoColors.surfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: 'Aprovados',
                  value: '${metrics.aprovados}',
                  color: DipontoColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricChip(
                  label: 'Reprovados',
                  value: '${metrics.reprovados}',
                  color: DipontoColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricChip(
                  label: PortugueseLabels.rendimento,
                  value: '${metrics.yieldPct.toStringAsFixed(1)}%',
                  color: DipontoColors.primaryLight,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DipontoColors.surface,
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
              fontSize: 11,
              color: DipontoColors.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de potência dos últimos testes.
class BatchLivePowerChart extends StatelessWidget {
  const BatchLivePowerChart({
    super.key,
    required this.tests,
    this.potenciaMin,
    this.potenciaMax,
    this.maxBars = 20,
  });

  final List<TestResult> tests;
  final double? potenciaMin;
  final double? potenciaMax;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return ActionSectionCard(
        icon: Icons.bar_chart,
        title: 'Potência por teste',
        child: const EmptyStateView(
          icon: Icons.bar_chart_outlined,
          title: 'Nenhum teste registrado',
          subtitle: 'Pressione o botão na bancada para iniciar o primeiro teste.',
        ),
      );
    }

    final chartTests = tests.take(maxBars).toList().reversed.toList();
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

    return ActionSectionCard(
      icon: Icons.bar_chart,
      title: 'Potência por teste',
      subtitle: potenciaMin != null && potenciaMax != null
          ? 'Faixa ${potenciaMin!.toStringAsFixed(1)}–${potenciaMax!.toStringAsFixed(1)} W · últimos ${chartTests.length}'
          : 'Últimos ${chartTests.length} testes',
      child: SimpleBarChart(bars: bars, height: 160),
    );
  }
}

/// Lista compacta dos testes recentes + link para histórico completo.
class BatchLiveRecentTests extends StatelessWidget {
  const BatchLiveRecentTests({
    super.key,
    required this.tests,
    this.maxVisible = 10,
    this.onViewAll,
  });

  final List<TestResult> tests;
  final int maxVisible;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return ActionSectionCard(
        icon: Icons.history,
        title: 'Testes recentes',
        child: const EmptyStateView(
          icon: Icons.history,
          title: 'Sem testes ainda',
          subtitle: 'Os resultados aparecerão aqui após cada teste.',
        ),
      );
    }

    final recent = tests.take(maxVisible).toList();
    final dateFmt = DateFormat('HH:mm:ss');

    return ActionSectionCard(
      icon: Icons.history,
      title: 'Testes recentes',
      subtitle: '${tests.length} no lote',
      trailing: tests.length > maxVisible
          ? TextButton(onPressed: onViewAll, child: const Text('Ver todos'))
          : null,
      child: Column(
        children: [
          for (final t in recent)
            _TestListTile(test: t, dateFmt: dateFmt),
        ],
      ),
    );
  }
}

class _TestListTile extends StatelessWidget {
  const _TestListTile({required this.test, required this.dateFmt});

  final TestResult test;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final approved = isApprovedVeredito(test.veredito);
    final color = approved ? DipontoColors.success : DipontoColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          approved ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: color,
          size: 20,
        ),
        title: Text(
          '${test.veredito} · ${test.potenciaMedia.toStringAsFixed(2)} W',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Seq ${test.sequencial}'
          '${test.serial != null ? ' · ${test.serial}' : ''}'
          ' · ${dateFmt.format(test.createdAt.toLocal())}',
        ),
      ),
    );
  }
}

/// Detalhes colapsáveis: contexto do lote + seriais emitidos.
class BatchLiveDetailsExpansion extends StatelessWidget {
  const BatchLiveDetailsExpansion({
    super.key,
    required this.numeroOp,
    required this.productName,
    required this.bancadaLabel,
    required this.operador,
    required this.estado,
    this.batch,
    required this.tests,
  });

  final String numeroOp;
  final String? productName;
  final String bancadaLabel;
  final String operador;
  final DeviceFsmState estado;
  final BatchConfig? batch;
  final List<TestResult> tests;

  @override
  Widget build(BuildContext context) {
    final seriais = [
      for (final t in tests)
        if (t.serial != null) t.serial!,
    ];

    return ActionSectionCard(
      icon: Icons.info_outline,
      title: 'Detalhes do lote',
      accentColor: DipontoColors.onSurface.withValues(alpha: 0.5),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 8),
          title: const Text('Contexto e seriais'),
          subtitle: Text('$numeroOp · $bancadaLabel'),
          children: [
            _InfoRow('OP', numeroOp),
            _InfoRow('Produto', productName ?? '—'),
            _InfoRow('Bancada', bancadaLabel),
            _InfoRow('Operador', operador),
            _InfoRow('Estado', estado.label),
            if (batch != null) ...[
              _InfoRow(
                'Potência',
                '${batch!.potenciaMin.toStringAsFixed(1)}–${batch!.potenciaMax.toStringAsFixed(1)} W',
              ),
              _InfoRow('Meta', '${batch!.quantidadeTotal} peças'),
            ],
            if (seriais.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Seriais emitidos (${seriais.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final serial in seriais)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.qr_code_2, size: 16),
                      label: Text(serial, style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ],
        ),
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
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: DipontoColors.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painel simplificado (operador)
// ---------------------------------------------------------------------------

/// Cartão grande: APROVADO / REPROVADO + potência + contexto mínimo.
class BatchLiveOperatorHero extends StatelessWidget {
  const BatchLiveOperatorHero({
    super.key,
    required this.estado,
    required this.tests,
    required this.numeroOp,
    this.productName,
    this.liveResult,
    this.potenciaMin,
    this.potenciaMax,
    this.mqttDisconnected = false,
    this.filaOffline = 0,
    this.awaitingMqtt = false,
    this.proximoSequencial,
    this.deviceOffline = false,
    this.lastRejectionMotivo,
  });

  final DeviceFsmState estado;
  final List<TestResult> tests;
  final String numeroOp;
  final String? productName;
  final TestResultMessage? liveResult;
  final double? potenciaMin;
  final double? potenciaMax;
  final bool mqttDisconnected;
  final int filaOffline;
  final bool awaitingMqtt;
  /// Próxima peça esperada (firmware heartbeat).
  final int? proximoSequencial;
  /// Bancada sem heartbeat recente mas lote ativo.
  final bool deviceOffline;
  final String? lastRejectionMotivo;

  @override
  Widget build(BuildContext context) {
    final cooldownBlocked = isCooldownRejection(lastRejectionMotivo);
    final batchReady = estado == DeviceFsmState.batchReady;

    if (liveResult != null && liveResult!.numeroOp == numeroOp) {
      final approved = liveResult!.isApproved;
      final accent = approved ? DipontoColors.success : DipontoColors.error;
      return _OperatorHeroCard(
        accent: accent,
        child: Column(
          children: [
            Text(
              liveResult!.veredito,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 1.2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '${liveResult!.potenciaMedia.toStringAsFixed(2)} W',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (potenciaMin != null && potenciaMax != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Faixa: ${potenciaMin!.toStringAsFixed(1)}–${potenciaMax!.toStringAsFixed(1)} W',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DipontoColors.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ),
            const SizedBox(height: 12),
            _OperatorStatusPill(
              icon: Icons.format_list_numbered,
              label: 'Seq ${liveResult!.sequencial}',
            ),
            _OperatorActionHint(
              cooldownBlocked: cooldownBlocked,
              proximoSequencial: proximoSequencial,
              batchReady: batchReady,
            ),
          ],
        ),
      );
    }

    if (estado == DeviceFsmState.testing) {
      return _OperatorHeroCard(
        accent: DipontoColors.primary,
        child: Column(
          children: [
            const _TestingPulseIndicator(),
            const SizedBox(height: 24),
            Text(
              'Testando',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DipontoColors.primary,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Medindo potência na bancada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DipontoColors.onSurface.withValues(alpha: 0.8),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Aguarde o resultado — não pressione o botão novamente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DipontoColors.onSurface.withValues(alpha: 0.55),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (awaitingMqtt) {
      return _OperatorHeroCard(
        accent: Colors.orange,
        child: Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            Text(
              'Aguardando MQTT',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              filaOffline > 0
                  ? 'Resultado na fila da bancada ($filaOffline) — sincronizando…'
                  : 'Resultado do teste a caminho — aguarde',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DipontoColors.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final latest = _resolveLatest();
    if (latest == null) {
      final offline = deviceOffline || mqttDisconnected;
      final accent = offline ? DipontoColors.error : DipontoColors.primary;
      return _OperatorHeroCard(
        accent: accent,
        child: Column(
          children: [
            Icon(
              offline ? Icons.cloud_off : Icons.touch_app,
              size: 56,
              color: accent,
            ),
            const SizedBox(height: 16),
            Text(
              offline ? 'Bancada offline' : 'Pressione o botão',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              offline
                  ? 'Confira o visor da bancada (OLED). O app reconcilia ao reconectar.'
                  : 'O teste só inicia pelo botão físico da bancada',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DipontoColors.onSurface.withValues(alpha: 0.65),
                  ),
              textAlign: TextAlign.center,
            ),
            if (proximoSequencial != null && !cooldownBlocked) ...[
              const SizedBox(height: 12),
              Text(
                'Próxima peça: sequencial $proximoSequencial',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (cooldownBlocked)
              _OperatorActionHint(
                cooldownBlocked: true,
                proximoSequencial: proximoSequencial,
                batchReady: batchReady,
              ),
            if (filaOffline > 0) ...[
              const SizedBox(height: 16),
              _OperatorStatusPill(
                icon: Icons.queue,
                label: 'Fila offline: $filaOffline',
                color: Colors.orange,
              ),
            ],
          ],
        ),
      );
    }

    final valid = isValidVeredito(latest.veredito);
    final approved = valid && isApprovedVeredito(latest.veredito);
    final accent = !valid
        ? Colors.orange
        : approved
            ? DipontoColors.success
            : DipontoColors.error;
    final verdictLabel = !valid ? 'Sem veredito' : latest.veredito;

    return _OperatorHeroCard(
      accent: accent,
      child: Column(
        children: [
          Text(
            verdictLabel,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 1.2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${latest.potenciaMedia.toStringAsFixed(2)} W',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          if (potenciaMin != null && potenciaMax != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Faixa ${potenciaMin!.toStringAsFixed(1)}–${potenciaMax!.toStringAsFixed(1)} W',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DipontoColors.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _OperatorStatusPill(icon: Icons.tag, label: 'OP $numeroOp'),
              if (productName != null)
                _OperatorStatusPill(icon: Icons.inventory_2_outlined, label: productName!),
              _OperatorStatusPill(
                icon: Icons.format_list_numbered,
                label: 'Seq ${latest.sequencial}',
              ),
              if (latest.serial != null)
                _OperatorStatusPill(icon: Icons.qr_code_2, label: latest.serial!),
            ],
          ),
          _OperatorActionHint(
            cooldownBlocked: cooldownBlocked,
            proximoSequencial: proximoSequencial,
            batchReady: batchReady,
          ),
        ],
      ),
    );
  }

  _LatestDisplay? _resolveLatest() {
    if (liveResult != null) {
      return _LatestDisplay(
        veredito: liveResult!.veredito,
        potenciaMedia: liveResult!.potenciaMedia,
        sequencial: liveResult!.sequencial,
      );
    }
    if (tests.isEmpty) return null;
    final t = tests.first;
    return _LatestDisplay(
      veredito: t.veredito,
      potenciaMedia: t.potenciaMedia,
      sequencial: t.sequencial,
      serial: t.serial,
      timestamp: t.createdAt,
    );
  }
}

/// Barra de progresso enxuta para operador.
class BatchLiveOperatorProgress extends StatelessWidget {
  const BatchLiveOperatorProgress({
    super.key,
    required this.metrics,
    required this.meta,
  });

  final BatchMetrics metrics;
  final int meta;

  @override
  Widget build(BuildContext context) {
    if (meta <= 0) return const SizedBox.shrink();

    final progress = (metrics.aprovados / meta).clamp(0.0, 1.0);
    final pendentes = metrics.pendentes(meta);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meta do lote',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '$pendentes pendentes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DipontoColors.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${metrics.aprovados}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: DipontoColors.success,
                            ),
                      ),
                      TextSpan(
                        text: ' / $meta',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DipontoColors.onSurface.withValues(alpha: 0.75),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: DipontoColors.success,
                backgroundColor: DipontoColors.surfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faixa compacta de status (MQTT, bancada, fila).
class BatchLiveOperatorStatusStrip extends StatelessWidget {
  const BatchLiveOperatorStatusStrip({
    super.key,
    required this.bancadaLabel,
    required this.estado,
    required this.mqttDisconnected,
    this.filaOffline = 0,
    this.awaitingMqtt = false,
  });

  final String bancadaLabel;
  final DeviceFsmState estado;
  final bool mqttDisconnected;
  final int filaOffline;
  final bool awaitingMqtt;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _OperatorStatusPill(
          icon: mqttDisconnected ? Icons.wifi_off : Icons.wifi,
          label: mqttDisconnected ? 'MQTT off' : bancadaLabel,
          color: mqttDisconnected ? DipontoColors.error : DipontoColors.success,
        ),
        _OperatorStatusPill(icon: Icons.memory, label: estado.label),
        if (filaOffline > 0)
          _OperatorStatusPill(
            icon: Icons.queue,
            label: 'Fila $filaOffline',
            color: Colors.orange,
          ),
        if (awaitingMqtt)
          const _OperatorStatusPill(
            icon: Icons.sync,
            label: 'Aguardando MQTT',
            color: Colors.orange,
          ),
      ],
    );
  }
}

/// Alerta compacto para operador (rejeição MQTT, NVS).
class BatchLiveOperatorAlert extends StatelessWidget {
  const BatchLiveOperatorAlert({
    super.key,
    required this.message,
    this.isError = true,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? DipontoColors.error : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.warning_amber_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hint abaixo do veredito: bloqueio (cooldown) ou próxima peça liberada.
class _OperatorActionHint extends StatelessWidget {
  const _OperatorActionHint({
    required this.cooldownBlocked,
    this.proximoSequencial,
    required this.batchReady,
  });

  final bool cooldownBlocked;
  final int? proximoSequencial;
  final bool batchReady;

  @override
  Widget build(BuildContext context) {
    if (cooldownBlocked) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(Icons.pause_circle_outline, color: Colors.orange.shade800, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aguarde — peça já aprovada. Libera em alguns segundos.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (batchReady && proximoSequencial != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'Próxima peça liberada — sequencial $proximoSequencial',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: DipontoColors.primary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _OperatorHeroCard extends StatelessWidget {
  const _OperatorHeroCard({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.35), width: 2),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _TestingPulseIndicator extends StatefulWidget {
  const _TestingPulseIndicator();

  @override
  State<_TestingPulseIndicator> createState() => _TestingPulseIndicatorState();
}

class _TestingPulseIndicatorState extends State<_TestingPulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final scale = 0.85 + (Curves.easeOut.transform(t) * 0.25);
          final opacity = (1 - t).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DipontoColors.primary.withValues(alpha: opacity * 0.45),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DipontoColors.primary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: DipontoColors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 32,
                  color: DipontoColors.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OperatorStatusPill extends StatelessWidget {
  const _OperatorStatusPill({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DipontoColors.onSurface.withValues(alpha: 0.75);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DipontoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

void showBatchHistorySheet(BuildContext context, List<TestResult> tests) {
  final dateFmt = DateFormat('dd/MM HH:mm:ss');
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              'Histórico completo (${tests.length})',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: tests.length,
              itemBuilder: (_, i) {
                final t = tests[i];
                final approved = isApprovedVeredito(t.veredito);
                final color = approved ? DipontoColors.success : DipontoColors.error;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: color.withValues(alpha: 0.08),
                  child: ListTile(
                    dense: true,
                    title: Text('${t.veredito} — ${t.potenciaMedia.toStringAsFixed(2)} W'),
                    subtitle: Text(
                      'Seq ${t.sequencial}'
                      '${t.serial != null ? ' · ${t.serial}' : ''}'
                      '${t.operador != null ? '\n${t.operador}' : ''}'
                      '\n${dateFmt.format(t.createdAt.toLocal())}',
                    ),
                    isThreeLine: t.operador != null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Painel lateral: seriais aguardando gravação laser (serial + modelo).
class BatchLiveEngravingPanel extends ConsumerWidget {
  const BatchLiveEngravingPanel({
    required this.numeroOp,
    this.idProduto,
    super.key,
  });

  final String numeroOp;
  final String? idProduto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(batchLiveMarkQueueProvider(numeroOp));
    final markFailure = ref.watch(markFailureProvider);
    final dateFmt = DateFormat('HH:mm');

    return Material(
      color: DipontoColors.surface.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.precision_manufacturing_outlined, color: DipontoColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gravação',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Gerar serial manual',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => showManualSerialDialog(
                    context,
                    ref,
                    initialNumeroOp: numeroOp,
                    initialIdProduto: idProduto,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: queueAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => Text(
                'F2 no DiatuCAD grava serial e modelo do próximo da fila.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DipontoColors.onSurface.withValues(alpha: 0.65),
                    ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Text(
                    'F2 no DiatuCAD grava serial e modelo do próximo da fila.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DipontoColors.onSurface.withValues(alpha: 0.65),
                        ),
                  );
                }
                return LaserMarkCallout(entry: entries.first);
              },
            ),
          ),
          if (markFailure != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                markFailure,
                style: const TextStyle(color: DipontoColors.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: queueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(fontSize: 12))),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Nenhum serial aguardando gravação nesta OP.\n'
                        'Aprovações e seriais manuais aparecem aqui.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DipontoColors.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => MarkQueueEntryTile(
                    entry: entries[i],
                    index: i,
                    dateFmt: dateFmt,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
