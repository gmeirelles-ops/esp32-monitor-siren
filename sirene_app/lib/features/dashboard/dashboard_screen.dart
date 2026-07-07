import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/dropdown_value.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/section_intro.dart';
import '../../shared/widgets/status_chip_header.dart';
import '../../shared/widgets/simple_bar_chart.dart';
import '../bancadas/bancadas_provider.dart';
import '../operators/operators_provider.dart';
import '../products/products_provider.dart';
import 'dashboard_batch_status.dart';
import '../../core/providers/core_providers.dart';
import '../../shared/reports/report_context.dart';
import '../../shared/reports/report_export_format.dart';
import '../../shared/reports/report_pdf_export.dart';
import '../../shared/reports/report_xml_export.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _exportReport(BuildContext context, WidgetRef ref, DashboardData data) async {
    final picked = await pickReportExportOptions(context);
    if (picked == null || !context.mounted) return;

    final filters = ref.read(dashboardFiltersProvider);
    final ctx = await loadReportContext(ref);

    try {
      final path = await exportReportFile(
        format: picked.format,
        basename: 'painel',
        buildPdf: () => buildDashboardPdf(
          data: data,
          filters: filters,
          stationId: ctx.stationId,
          operatorLabel: ctx.operatorLabel,
        ),
        buildXml: () => formatDashboardXml(
          data: data,
          filters: filters,
          stationId: ctx.stationId,
          operatorLabel: ctx.operatorLabel,
        ),
        openPrintDialog: picked.openPrint,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${picked.format.label} salvo: $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $e')),
      );
    }
  }

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
    final yieldTarget = ref.watch(yieldTargetPctProvider);

    return Scaffold(
      appBar: screenAppBar(
        context,
        title: 'Painel',
        actions: [
          dashboardAsync.maybeWhen(
            data: (data) => IconButton(
              tooltip: 'Exportar relatório',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _exportReport(context, ref, data),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar painel: $e')),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.summary.total > 0)
              StatusChipHeader(
                chips: [
                  StatusChipData(
                    icon: Icons.fact_check_outlined,
                    label: '${data.summary.total} testados',
                    color: DipontoColors.primary,
                  ),
                  StatusChipData(
                    icon: Icons.trending_up,
                    label: '${data.summary.yieldPct.toStringAsFixed(1)}% rendimento',
                    color: DipontoColors.success,
                  ),
                  StatusChipData(
                    icon: Icons.cancel_outlined,
                    label: '${data.summary.reprovados} reprovados',
                    color: DipontoColors.error,
                  ),
                  StatusChipData(
                    icon: Icons.warning_amber_outlined,
                    label: '${data.faults.fold<int>(0, (s, f) => s + f.count)} falhas HW',
                    color: DipontoColors.primaryLight,
                  ),
                ],
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  DesktopFormLayout(
                    maxWidth: 1280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionIntro(
                          title: 'Painel de produção',
                          subtitle: 'Métricas do período, throughput e alertas de hardware.',
                          icon: Icons.insights_outlined,
                        ),
                        ActionSectionCard(
                          icon: Icons.filter_list,
                          title: 'Filtros',
                          subtitle: 'Período, lote, produto e bancada',
                          child: _FiltersSection(
                            filters: filters,
                            options: data.filterOptions,
                            bancadas: bancadas,
                          ),
                        ),
                        if (data.summary.total == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
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
                          if (data.oee != null)
                            ActionSectionCard(
                              icon: Icons.speed,
                              title: 'OEE simplificado',
                              child: Text(
                                'OEE ${data.oee!.oeePct.toStringAsFixed(1)}% '
                                '(disp. ${data.oee!.availabilityPct.toStringAsFixed(0)}% · '
                                'perf. ${data.oee!.performancePct.toStringAsFixed(0)}% · '
                                'qual. ${data.oee!.qualityPct.toStringAsFixed(0)}%)',
                              ),
                            ),
                          ActionSectionCard(
                            icon: Icons.bar_chart,
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
                          ActionSectionCard(
                            icon: Icons.percent,
                            title: 'Análise de rendimento diário',
                            subtitle: 'Meta: ${yieldTarget.toStringAsFixed(0)}%',
                            accentColor: DipontoColors.success,
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
                          if (data.batchSummaries.isNotEmpty)
                            ActionSectionCard(
                              icon: Icons.table_chart_outlined,
                              title: 'Produção por lote',
                              child: SingleChildScrollView(
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
                                            _StatusChip(
                                              status: batchStatusFor(
                                                batch,
                                                yieldTarget: yieldTarget,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          if (data.recentAlerts.isNotEmpty)
                            ActionSectionCard(
                              icon: Icons.warning_amber_outlined,
                              title: 'Alertas de hardware recentes',
                              accentColor: DipontoColors.error,
                              child: Column(
                                children: [
                                  for (final alert in data.recentAlerts)
                                    ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.warning_amber_outlined,
                                        color: DipontoColors.error,
                                      ),
                                      title: Text(alert.falha),
                                      subtitle: Text(
                                        '${alert.deviceId} · '
                                        '${DateFormat('dd/MM HH:mm').format(alert.createdAt.toLocal())}',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (data.operatorProductivity.isNotEmpty)
                            ActionSectionCard(
                              icon: Icons.people_outline,
                              title: 'Produtividade por operador',
                              child: Column(
                                children: [
                                  for (final op in data.operatorProductivity.take(10))
                                    ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(op.label),
                                      trailing: Text(
                                        '${op.total} testes · ${op.yieldPct.toStringAsFixed(0)}%',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (data.faults.isNotEmpty)
                            ActionSectionCard(
                              icon: Icons.build_circle_outlined,
                              title: 'Falhas de hardware',
                              accentColor: DipontoColors.error,
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
              value: validDropdownValue(filters.numeroOp, options.ops),
              items: options.ops,
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearNumeroOp: true)
                  : filters.copyWith(numeroOp: v),
            ),
            _FilterDropdown(
              label: 'Produto',
              value: validDropdownValue(filters.idProduto, options.products),
              items: options.products,
              itemLabel: (id) => formatProductLabel(id, catalog: catalog),
              onChanged: (v) => notifier.state = v == null
                  ? filters.copyWith(clearIdProduto: true)
                  : filters.copyWith(idProduto: v),
            ),
            _FilterDropdown(
              label: 'Bancada',
              value: validDropdownValue(filters.deviceId, options.devices),
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
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Todos', overflow: TextOverflow.ellipsis),
          ),
          for (final item in items)
            DropdownMenuItem<String?>(
              value: item,
              child: Text(
                itemLabel?.call(item) ?? item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        selectedItemBuilder: (context) => [
          const Text('Todos', overflow: TextOverflow.ellipsis),
          for (final item in items)
            Text(
              itemLabel?.call(item) ?? item,
              overflow: TextOverflow.ellipsis,
            ),
        ],
        onChanged: onChanged,
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
