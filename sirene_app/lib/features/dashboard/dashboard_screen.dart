import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/simple_bar_chart.dart';
import '../bancadas/bancadas_provider.dart';
import '../operators/operators_provider.dart';
import '../products/products_provider.dart';
import 'dashboard_batch_status.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGestor = ref.watch(activeOperatorIsGestorProvider);
    if (!isGestor) {
      return Scaffold(
        appBar: screenAppBar(context, title: 'Painel'),
        body: const Center(
          child: Text('Acesso restrito a gestores. Faça login com um operador marcado como Gestor.'),
        ),
      );
    }

    final filters = ref.watch(dashboardFiltersProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: screenAppBar(context, title: 'Painel'),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar painel: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            DesktopFormLayout(
              maxWidth: 1280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FiltersSection(
                    filters: filters,
                    options: data.filterOptions,
                    bancadas: bancadas,
                  ),
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
                    _KpiRow(
                      summary: data.summary,
                      faults: data.faults,
                      yieldTrendPct: data.yieldTrendPct,
                      reprovadosTrendPct: data.reprovadosTrendPct,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _throughputTitle(filters.period),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            SimpleBarChart(
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Análise de rendimento diário',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            SimpleBarChart(
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
                            const SizedBox(height: 8),
                            Text(
                              'Meta: ${defaultYieldTargetPct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: DipontoColors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (data.batchSummaries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Produção por lote',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Nº Lote')),
                                    DataColumn(label: Text('Testes totais')),
                                    DataColumn(label: Text('Aprovados')),
                                    DataColumn(label: Text('Reprovados')),
                                    DataColumn(label: Text('Rendimento (%)')),
                                    DataColumn(label: Text('Status')),
                                  ],
                                  rows: [
                                    for (final batch in data.batchSummaries)
                                      DataRow(
                                        cells: [
                                          DataCell(Text('OP ${batch.numeroOp}')),
                                          DataCell(Text('${batch.total} testes')),
                                          DataCell(Text('${batch.aprovados}')),
                                          DataCell(
                                            Text(
                                              '${batch.reprovados}',
                                              style: batch.reprovados > 0
                                                  ? const TextStyle(color: DipontoColors.error)
                                                  : null,
                                            ),
                                          ),
                                          DataCell(Text('${batch.yieldPct.toStringAsFixed(1)}%')),
                                          DataCell(
                                            _StatusChip(status: batchStatusFor(batch)),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (data.faults.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Falhas de hardware',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              SimpleBarChart(
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
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
      DashboardPeriod.today => 'Visão geral do atendimento (hoje)',
      DashboardPeriod.week => 'Visão geral do atendimento (7 dias)',
      DashboardPeriod.all => 'Visão geral do atendimento (30 dias)',
    };
  }
}

class _FiltersSection extends ConsumerWidget {
  const _FiltersSection({
    required this.filters,
    required this.options,
    required this.bancadas,
  });

  final DashboardFilters filters;
  final DashboardFilterOptions options;
  final Map<String, int> bancadas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardFiltersProvider.notifier);
    final catalog = ref.watch(productsStreamProvider).maybeWhen(
          data: productCatalogById,
          orElse: () => <String, Product>{},
        );

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
              itemLabel: (id) => formatProductLabel(id, catalog: catalog),
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearIdProduto: true)
                  : filters.copyWith(idProduto: v),
            ),
            _FilterDropdown(
              label: 'Bancada',
              value: filters.deviceId,
              items: options.devices,
              itemLabel: (id) => formatBancadaLabelFromMap(id, bancadas),
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
    this.itemLabel,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String item)? itemLabel;

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
            DropdownMenuItem<String?>(
              value: item,
              child: Text(itemLabel?.call(item) ?? item),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.summary,
    required this.faults,
    this.yieldTrendPct,
    this.reprovadosTrendPct,
  });

  final ProductionSummary summary;
  final List<FaultCount> faults;
  final double? yieldTrendPct;
  final double? reprovadosTrendPct;

  @override
  Widget build(BuildContext context) {
    final totalFaults = faults.fold<int>(0, (sum, f) => sum + f.count);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(
          label: 'Testado',
          value: '${summary.total}',
          icon: Icons.fact_check_outlined,
          trend: yieldTrendPct,
          trendLabel: yieldTrendPct != null ? 'aprovados vs ontem' : null,
        ),
        _KpiCard(
          label: PortugueseLabels.rendimento,
          value: '${summary.yieldPct.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: DipontoColors.success,
        ),
        _KpiCard(
          label: 'Reprovados',
          value: '${summary.reprovados}',
          icon: Icons.cancel_outlined,
          color: DipontoColors.error,
          trend: reprovadosTrendPct,
          trendLabel: reprovadosTrendPct != null ? 'vs ontem' : null,
        ),
        _KpiCard(
          label: 'Falhas HW',
          value: '$totalFaults',
          icon: Icons.warning_amber_outlined,
          color: DipontoColors.primary,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.trend,
    this.trendLabel,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final double? trend;
  final String? trendLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DipontoColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? DipontoColors.onSurface.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
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
          if (trend != null && trendLabel != null)
            Text(
              '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(0)}% $trendLabel',
              style: TextStyle(
                color: trend! >= 0 ? DipontoColors.success : DipontoColors.error,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BatchStatus.concluido => ('Concluído', DipontoColors.success),
      BatchStatus.revisar => ('Revisar', DipontoColors.error),
      BatchStatus.emAndamento => ('Em andamento', Colors.blueAccent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
