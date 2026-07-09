import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/section_intro.dart';
import '../../shared/widgets/status_chip_header.dart';
import 'laser_mark_callout.dart';
import 'manual_serial_dialog.dart';
import 'mark_queue_ui.dart';
import 'marking_providers.dart';
import 'remark_serial.dart';
import '../mqtt/mqtt_providers.dart';

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(foregroundColor: DipontoColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<void> showSerialSearchDialog(BuildContext context, WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final copy = remarkUiCopy(MarkingMode.laser, '');
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
                                    (r.veredito.toUpperCase() != 'APROVADO' &&
                                        r.veredito.toUpperCase() != 'MANUAL')
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
    return _LaserMarkQueueScreen(ref: ref);
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
            tooltip: 'Gerar serial para gravação',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => showManualSerialDialog(context, this.ref),
          ),
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
                  'Use + no topo para gerar serial manualmente, ou aguarde aprovações do lote. '
                  'Acione F2 no DiatuCAD para gravar.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: LaserMarkCallout(entry: entries.first),
              ),
              StatusChipHeader(
                chips: [
                  StatusChipData(
                    icon: Icons.precision_manufacturing,
                    label: '${entries.length} na fila',
                    color: DipontoColors.primary,
                  ),
                  if (markFailure != null)
                    StatusChipData(
                      icon: Icons.error_outline,
                      label: 'Falha gravação',
                      color: DipontoColors.error,
                    ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionIntro(
                            title: 'Fila de gravação laser',
                            subtitle:
                                'F2 no DiatuCAD grava serial (DataMatrix) e modelo (texto) de cada peça.',
                            icon: Icons.precision_manufacturing_outlined,
                          ),
                          if (markFailure != null)
                            ActionSectionCard(
                              icon: Icons.error_outline,
                              title: 'Falha de gravação',
                              accentColor: DipontoColors.error,
                              child: Text(
                                markFailure,
                                style: const TextStyle(color: DipontoColors.error),
                              ),
                            ),
                          ActionSectionCard(
                            icon: Icons.queue_play_next,
                            title: 'Próximos seriais',
                            subtitle: 'Serial + modelo via TCP ao DiatuCAD',
                            child: Column(
                              children: [
                                for (var i = 0; i < entries.length; i++) ...[
                                  if (i > 0) const Divider(height: 1),
                                  MarkQueueEntryTile(
                                    entry: entries[i],
                                    index: i,
                                    dateFmt: dateFmt,
                                    trailing: IconButton(
                                      tooltip: entries[i].status == 'in_progress'
                                          ? 'Aguarde a gravação terminar'
                                          : 'Remover da fila',
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      color: DipontoColors.error.withValues(alpha: 0.85),
                                      onPressed: entries[i].status == 'in_progress'
                                          ? null
                                          : () => _deleteMarkQueueEntry(
                                                context,
                                                this.ref,
                                                entries[i],
                                              ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _deleteMarkQueueEntry(
  BuildContext context,
  WidgetRef ref,
  MarkQueueEntry entry,
) async {
  final ok = await _confirmDelete(
    context,
    title: 'Remover da fila?',
    message: 'Excluir ${entry.serial} da fila de gravação laser?',
  );
  if (!ok || !context.mounted) return;

  await ref.read(databaseProvider).removeMarkQueueEntry(entry.id);
}
