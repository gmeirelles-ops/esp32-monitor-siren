import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_app_bar.dart';
import 'label_buffer_grouping.dart';
import 'label_print_logic.dart';
import 'label_printer.dart';
import 'marking_providers.dart';
import 'remark_serial.dart';
import 'zpl_generator.dart';
import '../mqtt/mqtt_providers.dart';

Future<void> showSerialSearchDialog(BuildContext context, WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final mode = ref.read(appConfigProvider).markingMode;
  final copy = remarkUiCopy(mode, '');
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
          title: Text('Buscar / ${copy.actionLabel.toLowerCase()} serial'),
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
                            trailing: r.serial == null ||
                                    r.veredito.toUpperCase() != 'APROVADO'
                                ? null
                                : TextButton.icon(
                                    icon: Icon(copy.icon, size: 18),
                                    label: Text(copy.actionLabel),
                                    onPressed: () async {
                                      final serial = r.serial!;
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (context.mounted) {
                                        await remarkSerialIfConfirmed(
                                          context: context,
                                          ref: ref,
                                          serial: serial,
                                          numeroOp: r.numeroOp,
                                        );
                                      }
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

class LabelsScreen extends ConsumerWidget {
  const LabelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markingMode = ref.watch(appConfigProvider).markingMode;
    if (markingMode == MarkingMode.laser) {
      return _LaserMarkQueueScreen(ref: ref);
    }

    final db = ref.watch(databaseProvider);
    final printFailure = ref.watch(printFailureProvider);
    final dateFmt = DateFormat('dd/MM HH:mm');

    final remarkCopy = remarkUiCopy(markingMode, '');
    return Scaffold(
      appBar: screenAppBar(
        context,
        title: 'Etiquetas',
        actions: [
          IconButton(
            tooltip: 'Buscar / ${remarkCopy.actionLabel.toLowerCase()} serial',
            icon: const Icon(Icons.search),
            onPressed: () => showSerialSearchDialog(context, ref),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (kDebugMode) ...[
                      OutlinedButton.icon(
                        onPressed: () => _downloadZpl(context, ref, entries),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text(PortugueseLabels.baixarArquivoZpl),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          'Salve o .zpl e compare com docs/label-reference/ '
                          '(ou envie pela Zebra Setup Utilities para teste).',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                    ElevatedButton.icon(
                      onPressed: entries.isEmpty
                          ? null
                          : () => _printPending(context, ref, entries),
                      icon: const Icon(Icons.print),
                      label: Text('Imprimir pendentes (${entries.length})'),
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

  Future<void> _downloadZpl(
    BuildContext context,
    WidgetRef ref,
    List<LabelBufferEntry> entries,
  ) async {
    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não há seriais no buffer para exportar')),
        );
      }
      return;
    }

    final op = entries.first.numeroOp;
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final db = ref.read(databaseProvider);
    final suggestedName = 'etiquetas_${op}_$timestamp.zpl';
    final items = await resolveLabelZplItems(db, entries.map((e) => e.serial).toList());
    final zpl = generateZplForItems(items);

    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'ZPL', extensions: ['zpl']),
      ],
    );
    if (location == null) return;

    await File(location.path).writeAsString(zpl);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arquivo salvo: ${location.path}')),
      );
    }
  }

  Future<void> _printPending(
    BuildContext context,
    WidgetRef ref,
    List<LabelBufferEntry> entries,
  ) async {
    final config = ref.read(appConfigProvider);
    final db = ref.read(databaseProvider);
    LabelPrinterTransport printer;
    try {
      printer = createLabelPrinterTransport(config);
    } catch (e) {
      ref.read(printFailureProvider.notifier).state =
          formatPrinterError(e, config.printerMode);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatPrinterError(e, config.printerMode))),
        );
      }
      return;
    }

    final items = await resolveLabelZplItems(db, entries.map((e) => e.serial).toList());
    final printEntries = <({int id, LabelZplItem item})>[];
    for (var i = 0; i < entries.length; i++) {
      printEntries.add((id: entries[i].id, item: items[i]));
    }
    final result = await printLabelBatches(
      entries: printEntries,
      sendZpl: (batch) => printer.sendZpl(generateZplLabelRow(batch)),
    );

    if (result.printedIds.isNotEmpty) {
      await db.removeLabelsFromBuffer(result.printedIds);
    }

    if (result.error != null) {
      ref.read(printFailureProvider.notifier).state =
          formatPrinterError(result.error!, config.printerMode);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatPrinterError(result.error!, config.printerMode))),
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

class _LaserMarkQueueScreen extends ConsumerWidget {
  const _LaserMarkQueueScreen({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = this.ref.watch(databaseProvider);
    final markFailure = this.ref.watch(markFailureProvider);
    final dateFmt = DateFormat('dd/MM HH:mm');

    return Scaffold(
      appBar: screenAppBar(
        context,
        title: 'Gravação',
        actions: [
          IconButton(
            tooltip: 'Buscar / regravar serial',
            icon: const Icon(Icons.search),
            onPressed: () => showSerialSearchDialog(context, this.ref),
          ),
          StreamBuilder<int>(
            stream: db.watchPendingMarkQueueCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.precision_manufacturing, color: DipontoColors.primary),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<MarkQueueEntry>>(
        stream: db.watchPendingMarkQueue(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return const EmptyStateView(
              icon: Icons.precision_manufacturing_outlined,
              title: 'Fila de gravação vazia',
              subtitle:
                  'Seriais aprovados aparecem aqui. Acione F2 no DiatuCAD para gravar o próximo.',
            );
          }

          return Column(
            children: [
              if (markFailure != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: DipontoColors.error.withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: DipontoColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          markFailure,
                          style: const TextStyle(color: DipontoColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${entries.length} serial(is) aguardando gravação no laser. '
                  'O próximo da fila será enviado quando o DiatuCAD solicitar via TCP.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      leading: Icon(
                        entry.pinned ? Icons.push_pin : Icons.looks_one_outlined,
                        color: DipontoColors.primary,
                      ),
                      title: Text(entry.serial),
                      subtitle: Text('OP ${entry.numeroOp} · ${dateFmt.format(entry.createdAt)}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
