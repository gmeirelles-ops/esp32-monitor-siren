import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/database/database.dart';
import '../../core/database/veredito.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/widgets/form_section_card.dart';
import '../bancadas/bancadas_provider.dart';
import '../dashboard/dashboard_filters.dart';
import '../labels/label_printer.dart';
import '../labels/zpl_generator.dart';
import '../mqtt/mqtt_providers.dart';
import 'batch_report_export.dart';
import 'report_filters.dart';

class BatchReportDetailScreen extends ConsumerStatefulWidget {
  const BatchReportDetailScreen({
    super.key,
    required this.numeroOp,
    required this.filters,
  });

  final String numeroOp;
  final ReportFilters filters;

  @override
  ConsumerState<BatchReportDetailScreen> createState() => _BatchReportDetailScreenState();
}

class _BatchReportDetailScreenState extends ConsumerState<BatchReportDetailScreen> {
  ReportVereditoFilter _veredito = ReportVereditoFilter.all;
  String _serialSearch = '';
  bool _exporting = false;
  Map<String, Product> _catalog = {};

  bool? get _approvedOnly => switch (_veredito) {
        ReportVereditoFilter.all => null,
        ReportVereditoFilter.approved => true,
        ReportVereditoFilter.rejected => false,
      };

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = await loadProductCatalog(ref.read(databaseProvider));
    if (mounted) setState(() => _catalog = catalog);
  }

  Future<List<TestResult>> _loadTests() {
    return ref.read(databaseProvider).testsForOp(
          widget.numeroOp,
          since: widget.filters.since,
          idProduto: widget.filters.idProduto,
          deviceId: widget.filters.deviceId,
          approvedOnly: _approvedOnly,
        );
  }

  List<TestResult> _applySerialFilter(List<TestResult> tests) {
    if (_serialSearch.trim().isEmpty) return tests;
    final q = _serialSearch.trim();
    return tests
        .where((t) => t.serial?.contains(q) == true || '${t.sequencial}'.contains(q))
        .toList();
  }

  Future<void> _exportDetail(List<TestResult> tests) async {
    setState(() => _exporting = true);
    try {
      final bancadaNumeros = await ref.read(databaseProvider).getBancadaNumeros();
      final path = await saveReportCsv(
        'lote_${widget.numeroOp.replaceAll(RegExp(r'[^\w\-]'), '_')}',
        formatBatchDetailCsv(
          widget.numeroOp,
          tests,
          productsById: _catalog,
          bancadaNumeros: bancadaNumeros,
        ),
      );
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

  Future<void> _reprintSerial(String serial) async {
    final config = ref.read(appConfigProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reimprimir etiqueta'),
        content: Text(
          'A impressora avançará uma linha inteira do rolo (3 posições). '
          'O serial $serial será impresso na primeira coluna; '
          'as outras duas saem em branco.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reimprimir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final db = ref.read(databaseProvider);
      final items = await resolveLabelZplItems(db, [serial]);
      final item = items.first;
      final printer = createLabelPrinterTransport(config);
      await printer.sendZpl(
        generateZplReprintRow(serial: item.serial, productName: item.productName),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Etiqueta $serial reenviada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatPrinterError(e, config.printerMode))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Lote ${widget.numeroOp}'),
        actions: [
          IconButton(
            tooltip: 'Exportar relatório',
            onPressed: _exporting
                ? null
                : () async {
                    final tests = _applySerialFilter(await _loadTests());
                    await _exportDetail(tests);
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
      body: FutureBuilder<List<TestResult>>(
        future: _loadTests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final allTests = snapshot.data ?? [];
          final tests = _applySerialFilter(allTests);
          final aprovados = allTests.where((t) => isApprovedVeredito(t.veredito)).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FormSectionCard(
                title: 'Resumo do lote',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${allTests.length} testes · $aprovados aprovados · ${allTests.length - aprovados} reprovados'),
                    if (allTests.isNotEmpty)
                      Text(
                        '${dateFmt.format(allTests.first.createdAt.toLocal())} — '
                        '${dateFmt.format(allTests.last.createdAt.toLocal())}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FormSectionCard(
                title: 'Filtros',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<ReportVereditoFilter>(
                      segments: const [
                        ButtonSegment(value: ReportVereditoFilter.all, label: Text('Todos')),
                        ButtonSegment(value: ReportVereditoFilter.approved, label: Text('Aprovados')),
                        ButtonSegment(value: ReportVereditoFilter.rejected, label: Text('Reprovados')),
                      ],
                      selected: {_veredito},
                      onSelectionChanged: (s) => setState(() => _veredito = s.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar serial ou sequencial',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _serialSearch = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FormSectionCard(
                title: 'Sirenes testadas (${tests.length})',
                child: tests.isEmpty
                    ? const Text('Nenhum teste com os filtros atuais.')
                    : Column(
                        children: [
                          for (final t in tests)
                            Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                leading: Icon(
                                  isApprovedVeredito(t.veredito)
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  color: isApprovedVeredito(t.veredito)
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                                title: Text(
                                  t.serial ?? 'Seq. ${t.sequencial} (sem serial)',
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                                subtitle: Text(
                                  '${t.veredito} · ${t.potenciaMedia.toStringAsFixed(1)} dB · '
                                  '${formatBancadaLabelFromMap(t.deviceId, bancadas)}\n'
                                  '${formatProductLabelFromSerial(t.serial, catalog: _catalog)} · '
                                  '${t.operador ?? "—"} · ${dateFmt.format(t.createdAt.toLocal())}',
                                ),
                                isThreeLine: true,
                                trailing: t.serial != null && isApprovedVeredito(t.veredito)
                                    ? IconButton(
                                        tooltip: 'Reimprimir etiqueta',
                                        icon: const Icon(Icons.label_outline, color: DipontoColors.primary),
                                        onPressed: () => _reprintSerial(t.serial!),
                                      )
                                    : null,
                              ),
                            ),
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
