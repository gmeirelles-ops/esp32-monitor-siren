import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import 'label_printer.dart';
import 'zpl_generator.dart';
import '../mqtt/mqtt_providers.dart';

class LabelsScreen extends ConsumerWidget {
  const LabelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiquetas'),
        actions: [
          FutureBuilder<int>(
            future: db.labelBufferCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
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
      body: FutureBuilder(
        future: db.getLabelBuffer(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return const Center(
              child: Text('Buffer vazio.\nSeriais aprovados aparecerão aqui.'),
            );
          }

          return Column(
            children: [
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
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      leading: const Icon(Icons.qr_code, color: DipontoColors.primary),
                      title: Text(entry.serial, style: const TextStyle(fontFamily: 'monospace')),
                      subtitle: Text('OP ${entry.numeroOp}'),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: entries.isEmpty
                      ? null
                      : () => _printPending(context, ref, entries.map((e) => e.serial).toList()),
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

  Future<void> _printPending(
    BuildContext context,
    WidgetRef ref,
    List<String> serials,
  ) async {
    final config = ref.read(appConfigProvider);
    final db = ref.read(databaseProvider);
    final printer = LabelPrinter(host: config.printerHost, port: config.printerPort);

    try {
      while (serials.isNotEmpty) {
        final batch = serials.take(3).toList();
        await printer.sendZpl(generateZplLabelRow(batch));
        serials = serials.sublist(batch.length);
      }
      final entries = await db.getLabelBuffer();
      await db.removeLabelsFromBuffer(entries.map((e) => e.id).toList());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etiquetas enviadas à impressora')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na impressão: $e')),
        );
      }
    }
  }
}
