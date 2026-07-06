import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/batch_metrics.dart';
import '../../core/database/database.dart';
import '../../core/database/veredito.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/simple_bar_chart.dart';
import '../mqtt/models/mqtt_messages.dart';

/// Cartão hero: estado FSM + último resultado do teste.
class BatchLiveLastTestHero extends StatelessWidget {
  const BatchLiveLastTestHero({
    super.key,
    required this.estado,
    required this.tests,
    this.liveResult,
    this.potenciaMin,
    this.potenciaMax,
  });

  final DeviceFsmState estado;
  final List<TestResult> tests;
  final TestResultMessage? liveResult;
  final double? potenciaMin;
  final double? potenciaMax;

  @override
  Widget build(BuildContext context) {
    if (estado == DeviceFsmState.testing) {
      return _HeroShell(
        accent: DipontoColors.primary,
        icon: Icons.hourglass_top,
        title: 'Teste em andamento',
        subtitle: 'Aguarde o resultado na bancada',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(color: DipontoColors.primary),
          ),
        ),
      );
    }

    final latest = _resolveLatest();
    if (latest == null) {
      return _HeroShell(
        accent: DipontoColors.primary,
        icon: Icons.touch_app,
        title: 'Pressione o botão no dispositivo',
        subtitle: estado == DeviceFsmState.batchReady
            ? 'O teste só inicia pelo botão físico da bancada'
            : estado.label,
        child: const SizedBox.shrink(),
      );
    }

    final approved = isApprovedVeredito(latest.veredito);
    final accent = approved ? DipontoColors.success : DipontoColors.error;
    final dateFmt = DateFormat('HH:mm:ss');

    return _HeroShell(
      accent: accent,
      icon: approved ? Icons.check_circle_outline : Icons.cancel_outlined,
      title: latest.veredito,
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
    final progress = meta > 0 ? (metrics.aprovados / meta).clamp(0.0, 1.0) : 0.0;

    return ActionSectionCard(
      icon: Icons.trending_up,
      title: 'Progresso do lote',
      subtitle: meta > 0
          ? '${metrics.pendentes(meta)} pendentes · ${metrics.total} ${PortugueseLabels.totalTestadas.toLowerCase()}'
          : '${metrics.total} ${PortugueseLabels.totalTestadas.toLowerCase()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (meta > 0) ...[
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
              color: DipontoColors.primary,
              backgroundColor: DipontoColors.surfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '${metrics.aprovados} / $meta aprovados',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
          ],
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
