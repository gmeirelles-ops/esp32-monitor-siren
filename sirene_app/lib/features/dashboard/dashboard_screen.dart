import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/simple_bar_chart.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(dashboardFiltersProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: screenAppBar(context, title: 'Painel'),
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
                  _FiltersSection(filters: filters, options: data.filterOptions),
                  const SizedBox(height: 16),
                  if (data.summary.total == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: EmptyStateView(
                        icon: Icons.insights_outlined,
                        title: filters.hasActiveFilters
                            ? 'Nenhum teste com estes filtros'
                            : 'Sem dados no período',
                        subtitle: filters.hasActiveFilters
                            ? 'Ajuste o período ou limpe os filtros de lote, produto ou dispositivo.'
                            : 'Os testes realizados aparecerão aqui como métricas de produção.',
                      ),
                    )
                  else ...[
                    _MetricsRow(summary: data.summary, faults: data.faults),
                    const SizedBox(height: 16),
                    FormSectionCard(
                      title: _throughputTitle(filters.period),
                      child: SimpleBarChart(
                        bars: [
                          for (final d in data.throughput)
                            SimpleBarChartBar(
                              label: '${d.day.day}/${d.day.month}',
                              value: d.total.toDouble(),
                              stackedValue: d.aprovados.toDouble(),
                            ),
                        ],
                        showLegend: true,
                        legendTotalLabel: 'Testado',
                        legendStackedLabel: 'Aprovados',
                        valueFormatter: (v) => v.toInt().toString(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormSectionCard(
                      title: 'Yield por dia (%)',
                      child: SimpleBarChart(
                        bars: [
                          for (final d in data.throughput)
                            SimpleBarChartBar(
                              label: '${d.day.day}/${d.day.month}',
                              value: d.total == 0 ? 0 : (d.aprovados / d.total) * 100,
                              color: DipontoColors.success,
                            ),
                        ],
                        defaultColor: DipontoColors.success,
                        valueFormatter: (v) => '${v.toStringAsFixed(0)}%',
                      ),
                    ),
                    if (data.batchSummaries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FormSectionCard(
                        title: 'Produção por lote',
                        child: Column(
                          children: [
                            for (final batch in data.batchSummaries)
                              Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  title: Text('OP ${batch.numeroOp}'),
                                  subtitle: Text(
                                    '${batch.aprovados} aprovados · ${batch.reprovados} reprovados · '
                                    'yield ${batch.yieldPct.toStringAsFixed(1)}%',
                                  ),
                                  trailing: Text(
                                    '${batch.total} testes',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (data.faults.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FormSectionCard(
                        title: 'Falhas de hardware',
                        child: SimpleBarChart(
                          bars: [
                            for (final f in data.faults)
                              SimpleBarChartBar(
                                label: f.falha,
                                value: f.count.toDouble(),
                                color: DipontoColors.error,
                              ),
                          ],
                          defaultColor: DipontoColors.error,
                          valueFormatter: (v) => v.toInt().toString(),
                        ),
                      ),
                    ],
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

  String _throughputTitle(DashboardPeriod period) {
    return switch (period) {
      DashboardPeriod.today => 'Throughput (hoje)',
      DashboardPeriod.week => 'Throughput (7 dias)',
      DashboardPeriod.all => 'Throughput (30 dias)',
    };
  }
}

class _FiltersSection extends ConsumerWidget {
  const _FiltersSection({required this.filters, required this.options});

  final DashboardFilters filters;
  final DashboardFilterOptions options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardFiltersProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DashboardPeriod>(
          segments: const [
            ButtonSegment(value: DashboardPeriod.today, label: Text('Hoje')),
            ButtonSegment(value: DashboardPeriod.week, label: Text('7 dias')),
            ButtonSegment(value: DashboardPeriod.all, label: Text('Tudo')),
          ],
          selected: {filters.period},
          onSelectionChanged: (s) =>
              notifier.state = filters.copyWith(period: s.first),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _FilterDropdown(
              label: 'Lote (OP)',
              value: filters.numeroOp,
              items: options.ops,
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearNumeroOp: true)
                  : filters.copyWith(numeroOp: v),
            ),
            _FilterDropdown(
              label: 'Produto',
              value: filters.idProduto,
              items: options.products,
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearIdProduto: true)
                  : filters.copyWith(idProduto: v),
            ),
            _FilterDropdown(
              label: 'Dispositivo',
              value: filters.deviceId,
              items: options.devices,
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearDeviceId: true)
                  : filters.copyWith(deviceId: v),
            ),
            if (filters.hasActiveFilters)
              TextButton.icon(
                onPressed: () => notifier.state = DashboardFilters(period: filters.period),
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Limpar filtros'),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String?>(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
          for (final item in items)
            DropdownMenuItem<String?>(value: item, child: Text(item)),
        ],
        onChanged: onChanged,
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
