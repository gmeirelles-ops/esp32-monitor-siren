import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../dashboard/dashboard_filters.dart';
import '../mqtt/mqtt_providers.dart';
import 'batch_report_detail_screen.dart';
import 'batch_report_export.dart';
import 'report_filters.dart';

final reportFiltersProvider = StateProvider<ReportFilters>((ref) => const ReportFilters());

class TraceabilityReportScreen extends ConsumerStatefulWidget {
  const TraceabilityReportScreen({super.key});

  @override
  ConsumerState<TraceabilityReportScreen> createState() => _TraceabilityReportScreenState();
}

class _TraceabilityReportScreenState extends ConsumerState<TraceabilityReportScreen> {
  bool _exporting = false;
  late final TextEditingController _opSearch;

  @override
  void initState() {
    super.initState();
    _opSearch = TextEditingController();
  }

  @override
  void dispose() {
    _opSearch.dispose();
    super.dispose();
  }

  Future<List<BatchReportSummary>> _loadBatches(ReportFilters filters) {
    return ref.read(databaseProvider).batchReportSummaries(
          since: filters.since,
          idProduto: filters.idProduto,
          deviceId: filters.deviceId,
          opContains: filters.opSearch,
        );
  }

  Future<void> _exportList(List<BatchReportSummary> batches) async {
    setState(() => _exporting = true);
    try {
      final path = await saveReportCsv('lotes', formatBatchListCsv(batches));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Relatório salvo: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openBatch(BatchReportSummary batch, ReportFilters filters) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BatchReportDetailScreen(
          numeroOp: batch.numeroOp,
          filters: filters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(reportFiltersProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: screenAppBar(
        context,
        title: 'Relatório',
        actions: [
          IconButton(
            tooltip: 'Exportar lista de lotes',
            onPressed: _exporting
                ? null
                : () async {
                    final batches = await _loadBatches(filters);
                    await _exportList(batches);
                  },
            icon: _exporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<BatchReportSummary>>(
        future: _loadBatches(filters),
        builder: (context, snapshot) {
          return ListView(
            children: [
              DesktopFormLayout(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormSectionCard(
                      title: 'Filtros',
                      child: _FiltersPanel(
                        filters: filters,
                        opSearchController: _opSearch,
                        onFiltersChanged: (f) => ref.read(reportFiltersProvider.notifier).state = f,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Erro: ${snapshot.error}'),
                      )
                    else ...[
                      Builder(
                        builder: (context) {
                          final batches = snapshot.data ?? [];
                          if (batches.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: EmptyStateView(
                                icon: Icons.inventory_2_outlined,
                                title: 'Nenhum lote encontrado',
                                subtitle: 'Ajuste o período ou os filtros para localizar lotes com testes.',
                              ),
                            );
                          }

                          return FormSectionCard(
                            title: 'Lotes (${batches.length})',
                            child: Column(
                              children: [
                                for (final batch in batches)
                                  Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.folder_open_outlined,
                                        color: DipontoColors.primary,
                                      ),
                                      title: Text(
                                        'OP ${batch.numeroOp}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        '${batch.aprovados} aprovados · ${batch.reprovados} reprovados · '
                                        'yield ${batch.yieldPct.toStringAsFixed(1)}%'
                                        '${batch.lastTestAt != null ? '\n${dateFmt.format(batch.lastTestAt!.toLocal())}' : ''}',
                                      ),
                                      isThreeLine: batch.lastTestAt != null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${batch.total}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                      onTap: () => _openBatch(batch, filters),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FiltersPanel extends ConsumerStatefulWidget {
  const _FiltersPanel({
    required this.filters,
    required this.opSearchController,
    required this.onFiltersChanged,
  });

  final ReportFilters filters;
  final TextEditingController opSearchController;
  final ValueChanged<ReportFilters> onFiltersChanged;

  @override
  ConsumerState<_FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends ConsumerState<_FiltersPanel> {
  Map<String, Product> _catalog = {};
  List<String> _productIds = [];
  List<String> _devices = [];
  Map<String, int> _bancadaNumeros = {};

  @override
  void initState() {
    super.initState();
    widget.opSearchController.text = widget.filters.opSearch;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final db = ref.read(databaseProvider);
    final catalog = await loadProductCatalog(db);
    final productIds = await db.distinctProducts();
    final devices = await db.deviceIdsOrderedByBancada();
    final bancadaNumeros = await db.getBancadaNumeros();
    if (mounted) {
      setState(() {
        _catalog = catalog;
        _productIds = productIds;
        _devices = devices;
        _bancadaNumeros = bancadaNumeros;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DashboardPeriod>(
          segments: const [
            ButtonSegment(value: DashboardPeriod.today, label: Text('Hoje')),
            ButtonSegment(value: DashboardPeriod.week, label: Text('7 dias')),
            ButtonSegment(value: DashboardPeriod.all, label: Text('Tudo')),
          ],
          selected: {widget.filters.period},
          onSelectionChanged: (s) {
            widget.onFiltersChanged(widget.filters.copyWith(period: s.first));
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.opSearchController,
          decoration: const InputDecoration(
            labelText: 'Buscar OP',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => widget.onFiltersChanged(widget.filters.copyWith(opSearch: v)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: widget.filters.idProduto,
                decoration: const InputDecoration(labelText: 'Produto'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final p in _productIds)
                    DropdownMenuItem(
                      value: p,
                      child: Text(formatProductLabel(p, catalog: _catalog)),
                    ),
                ],
                onChanged: (v) => widget.onFiltersChanged(
                  v == null
                      ? widget.filters.copyWith(clearIdProduto: true)
                      : widget.filters.copyWith(idProduto: v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: widget.filters.deviceId,
                decoration: const InputDecoration(labelText: 'Bancada'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final d in _devices)
                    DropdownMenuItem(
                      value: d,
                      child: Text(formatBancadaLabelFromMap(d, _bancadaNumeros)),
                    ),
                ],
                onChanged: (v) => widget.onFiltersChanged(
                  v == null
                      ? widget.filters.copyWith(clearDeviceId: true)
                      : widget.filters.copyWith(deviceId: v),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
