import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/global_app_bar_actions.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel'),
        actions: globalAppBarActions(),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar painel: $e')),
        data: (data) => ListView(
          children: [
            DesktopFormLayout(
              maxWidth: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<DashboardPeriod>(
                    segments: const [
                      ButtonSegment(value: DashboardPeriod.today, label: Text('Hoje')),
                      ButtonSegment(value: DashboardPeriod.week, label: Text('7 dias')),
                      ButtonSegment(value: DashboardPeriod.all, label: Text('Tudo')),
                    ],
                    selected: {period},
                    onSelectionChanged: (s) =>
                        ref.read(dashboardPeriodProvider.notifier).state = s.first,
                  ),
                  const SizedBox(height: 16),
                  if (data.summary.total == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: EmptyStateView(
                        icon: Icons.insights_outlined,
                        title: 'Sem dados no período',
                        subtitle:
                            'Os testes realizados aparecerão aqui como métricas de produção.',
                      ),
                    )
                  else ...[
                    _MetricsRow(summary: data.summary, faults: data.faults),
                    const SizedBox(height: 16),
                    FormSectionCard(
                      title: 'Throughput (7 dias)',
                      child: _BarChart(
                        bars: [
                          for (final d in data.throughput)
                            _Bar(
                              label: '${d.day.day}/${d.day.month}',
                              value: d.total.toDouble(),
                              secondary: d.aprovados.toDouble(),
                            ),
                        ],
                      ),
                    ),
                    if (data.faults.isNotEmpty)
                      FormSectionCard(
                        title: 'Falhas de hardware',
                        child: _BarChart(
                          color: DipontoColors.error,
                          bars: [
                            for (final f in data.faults)
                              _Bar(label: f.falha, value: f.count.toDouble()),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  FormSectionCard(
                    title: 'Alertas recentes',
                    child: data.recentAlerts.isEmpty
                        ? Text(
                            'Sem alertas recentes.',
                            style: TextStyle(
                              color: DipontoColors.onSurface.withValues(alpha: 0.6),
                            ),
                          )
                        : Column(
                            children: [
                              for (final a in data.recentAlerts)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const Icon(
                                    Icons.warning_amber_outlined,
                                    color: DipontoColors.error,
                                  ),
                                  title: Text(a.falha),
                                  subtitle: Text('${a.deviceId} — ${a.createdAt.toLocal()}'),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.summary, required this.faults});

  final ProductionSummary summary;
  final List<FaultCount> faults;

  @override
  Widget build(BuildContext context) {
    final totalFaults = faults.fold<int>(0, (sum, f) => sum + f.count);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(
          label: 'Testado',
          value: '${summary.total}',
          icon: Icons.fact_check_outlined,
        ),
        _MetricCard(
          label: 'Yield',
          value: '${summary.yieldPct.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: DipontoColors.success,
        ),
        _MetricCard(
          label: 'Reprovados',
          value: '${summary.reprovados}',
          icon: Icons.cancel_outlined,
          color: DipontoColors.error,
        ),
        _MetricCard(
          label: 'Falhas HW',
          value: '$totalFaults',
          icon: Icons.warning_amber_outlined,
          color: DipontoColors.primary,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DipontoColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? DipontoColors.onSurface.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: TextStyle(color: DipontoColors.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _Bar {
  const _Bar({required this.label, required this.value, this.secondary});

  final String label;
  final double value;
  final double? secondary;
}

/// Gráfico de barras leve, sem dependência externa.
class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars, this.color = DipontoColors.primary});

  final List<_Bar> bars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(1, (m, b) => b.value > m ? b.value : m);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      bar.value.toInt().toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: (bar.value / maxValue).clamp(0.02, 1.0),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.35),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              if (bar.secondary != null && bar.value > 0)
                                FractionallySizedBox(
                                  heightFactor: (bar.secondary! / bar.value).clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bar.label,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
