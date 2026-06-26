import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/simple_bar_chart.dart';
import 'analytics_models.dart';
import 'analytics_providers.dart';
import 'firestore_analytics_repository.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(analyticsFiltersProvider);
    final dataAsync = ref.watch(analyticsDashboardProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _formatDashboardError(e),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (data) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (data.dataStale)
              Card(
                color: Colors.orange.withValues(alpha: 0.15),
                child: const ListTile(
                  leading: Icon(Icons.cloud_off, color: Colors.orangeAccent),
                  title: Text('Dados possivelmente desatualizados'),
                  subtitle: Text(
                    'Nenhum teste recente na nuvem. Verifique se os postos têm sync habilitado.',
                  ),
                ),
              ),
            _FiltersBar(filters: filters, options: data.filterOptions),
            const SizedBox(height: 16),
            if (data.kpis.total == 0)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('Sem dados no período selecionado')),
              )
            else ...[
              _KpiRow(data: data),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visão geral do atendimento',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                              value: d.yieldPct,
                              color: DipontoColors.success,
                            ),
                        ],
                        defaultColor: DipontoColors.success,
                        valueFormatter: (v) => '${v.toStringAsFixed(0)}%',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Meta: ${defaultYieldTargetPct.toStringAsFixed(0)}%',
                        style: TextStyle(color: DipontoColors.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.batchRows.isNotEmpty) ...[
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
                              for (final row in data.batchRows)
                                DataRow(
                                  cells: [
                                    DataCell(Text('OP ${row.numeroOp}')),
                                    DataCell(Text('${row.total} testes')),
                                    DataCell(Text('${row.aprovados}')),
                                    DataCell(
                                      Text(
                                        '${row.reprovados}',
                                        style: row.reprovados > 0
                                            ? const TextStyle(color: DipontoColors.error)
                                            : null,
                                      ),
                                    ),
                                    DataCell(Text('${row.yieldPct.toStringAsFixed(1)}%')),
                                    DataCell(_StatusChip(status: row.status)),
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
            ],
          ],
        );
      },
    );
  }
}

String _formatDashboardError(Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Sem permissão no Firestore.\n\n'
        '1. Confirme que fez login com conta Firebase válida\n'
        '2. Na raiz do repo, rode:\n'
        '   npx firebase-tools login\n'
        '   npx firebase-tools deploy --only firestore:rules,firestore:indexes\n'
        '3. Reinicie o app gestor';
  }
  return 'Erro ao carregar painel: $error';
}

class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({required this.filters, required this.options});

  final AnalyticsFilters filters;
  final AnalyticsFilterOptions options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(analyticsFiltersProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<AnalyticsPeriod>(
          segments: const [
            ButtonSegment(value: AnalyticsPeriod.today, label: Text('Hoje')),
            ButtonSegment(value: AnalyticsPeriod.week, label: Text('7 dias')),
            ButtonSegment(value: AnalyticsPeriod.all, label: Text('Tudo')),
          ],
          selected: {filters.period},
          onSelectionChanged: (s) => notifier.state = filters.copyWith(period: s.first),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _dropdown(
              label: 'Lote (OP)',
              value: filters.numeroOp,
              items: options.ops,
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearNumeroOp: true)
                  : filters.copyWith(numeroOp: v),
            ),
            _dropdown(
              label: 'Produto',
              value: filters.idProduto,
              items: options.products,
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearIdProduto: true)
                  : filters.copyWith(idProduto: v),
            ),
            _dropdown(
              label: 'Bancada / Posto',
              value: filters.stationId,
              items: options.stations,
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearStationId: true)
                  : filters.copyWith(stationId: v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String?>(
        decoration: InputDecoration(labelText: label, isDense: true),
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

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.data});

  final AnalyticsDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(
          label: 'Testado',
          value: '${data.kpis.total}',
          icon: Icons.fact_check_outlined,
          trend: data.yieldTrendPct,
          trendLabel: 'vs ontem',
        ),
        _KpiCard(
          label: 'Rendimento',
          value: '${data.kpis.yieldPct.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: DipontoColors.success,
        ),
        _KpiCard(
          label: 'Reprovados',
          value: '${data.kpis.reprovados}',
          icon: Icons.cancel_outlined,
          color: DipontoColors.error,
          trend: data.reprovadosTrendPct,
          trendLabel: 'vs ontem',
        ),
        const _KpiCard(
          label: 'Falhas HW',
          value: '—',
          icon: Icons.warning_amber_outlined,
          subtitle: 'Sync posto apenas',
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
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final double? trend;
  final String? trendLabel;
  final String? subtitle;

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
          Text(label, style: TextStyle(color: DipontoColors.onSurface.withValues(alpha: 0.6))),
          if (trend != null && trendLabel != null)
            Text(
              '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(0)}% $trendLabel',
              style: TextStyle(
                color: trend! >= 0 ? DipontoColors.success : DipontoColors.error,
                fontSize: 12,
              ),
            ),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
