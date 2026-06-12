import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_app_bar.dart';
import 'label_buffer_grouping.dart';
import 'label_print_logic.dart';
import 'label_printer.dart';
import 'zpl_generator.dart';
import '../mqtt/mqtt_providers.dart';

class LabelsScreen extends ConsumerWidget {
  const LabelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final printFailure = ref.watch(printFailureProvider);
    final dateFmt = DateFormat('dd/MM HH:mm');

    return Scaffold(
      appBar: screenAppBar(
        context,
        title: 'Etiquetas',
        actions: [
          IconButton(
            tooltip: 'Buscar / reimprimir serial',
            icon: const Icon(Icons.search),
            onPressed: () => _showReprintDialog(context, ref),
          ),
          StreamBuilder<int>(
            stream: db.watchLabelBufferCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.label, color: DipontoColors.primary),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LabelBufferEntry>>(
        stream: db.watchLabelBuffer(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return const EmptyStateView(
              icon: Icons.label_outline,
              title: 'Buffer de etiquetas vazio',
              subtitle: 'Seriais aprovados nos testes aparecerão aqui para impressão.',
            );
          }

          final groups = groupLabelBufferByOp(entries);

          return Column(
            children: [
              if (printFailure != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: DipontoColors.error.withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.print_disabled, color: DipontoColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          printFailure,
                          style: const TextStyle(color: DipontoColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              if (entries.length % 3 != 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: DipontoColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    '${entries.length % 3} etiqueta(s) pendente(s) — aguardando múltiplo de 3 ou impressão manual',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: DipontoColors.primaryLight),
                  ),
                ),
              Expanded(
                child: ListView(
                  children: [
                    for (final group in groups)
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ExpansionTile(
                          leading: const Icon(Icons.inventory_2_outlined, color: DipontoColors.primary),
                          title: Text('OP ${group.numeroOp}'),
                          subtitle: Text('${group.count} etiqueta(s) pendente(s)'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (group.orphanCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text('${group.orphanCount} órfã(s)'),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: () => _printPending(context, ref, group.entries),
                                icon: const Icon(Icons.print, size: 18),
                                label: const Text('Imprimir lote'),
                              ),
                            ],
                          ),
                          children: [
                            for (final entry in group.entries)
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.qr_code, color: DipontoColors.primary),
                                title: Text(
                                  entry.serial,
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                                subtitle: Text(dateFmt.format(entry.createdAt.toLocal())),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: entries.isEmpty
                      ? null
                      : () => _printPending(context, ref, entries),
                  icon: const Icon(Icons.print),
                  label: Text('Imprimir pendentes (${entries.length})'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showReprintDialog(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final controller = TextEditingController();
    var results = <TestResult>[];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> search() async {
            final query = controller.text.trim();
            if (query.isEmpty) return;
            final found = await db.searchSerials(query);
            setState(() => results = found);
          }

          return AlertDialog(
            title: const Text('Buscar / reimprimir serial'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Serial (completo ou parcial)',
                      suffixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => search(),
                  ),
                  const SizedBox(height: 12),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Digite e busque um serial validado.'),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final r in results)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.qr_code, color: DipontoColors.primary),
                              title: Text(
                                r.serial ?? '—',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              subtitle: Text('OP ${r.numeroOp} — ${r.veredito}'),
                              trailing: r.serial == null
                                  ? null
                                  : TextButton.icon(
                                      icon: const Icon(Icons.print, size: 18),
                                      label: const Text('Reimprimir'),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _reprintSerial(context, ref, r.serial!);
                                      },
                                    ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
              ElevatedButton(onPressed: search, child: const Text('Buscar')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reprintSerial(BuildContext context, WidgetRef ref, String serial) async {
    final config = ref.read(appConfigProvider);
    final printer = LabelPrinter(host: config.printerHost, port: config.printerPort);
    try {
      await printer.sendZpl(generateZplLabelRow([serial]));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Etiqueta $serial reenviada à impressora')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na reimpressão: $e')),
        );
      }
    }
  }

  Future<void> _printPending(
    BuildContext context,
    WidgetRef ref,
    List<LabelBufferEntry> entries,
  ) async {
    final config = ref.read(appConfigProvider);
    final db = ref.read(databaseProvider);
    final printer = LabelPrinter(host: config.printerHost, port: config.printerPort);

    final printEntries = entries.map((e) => (id: e.id, serial: e.serial)).toList();
    final result = await printLabelBatches(
      entries: printEntries,
      sendZpl: (serials) => printer.sendZpl(generateZplLabelRow(serials)),
    );

    if (result.printedIds.isNotEmpty) {
      await db.removeLabelsFromBuffer(result.printedIds);
    }

    if (result.error != null) {
      ref.read(printFailureProvider.notifier).state =
          'Erro na impressão manual: ${result.error}';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na impressão: ${result.error}')),
        );
      }
      return;
    }

    ref.read(printFailureProvider.notifier).state = null;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etiquetas enviadas à impressora')),
      );
    }
  }
}
