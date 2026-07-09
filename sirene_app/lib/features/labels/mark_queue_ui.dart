import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../mqtt/mqtt_providers.dart';
import '../serial/itf_check_digit.dart';

/// Nome do produto (modelo) a partir do serial ITF.
Future<String?> resolveModelNameFromSerial(AppDatabase db, String serial) async {
  final idProduto = extractIdProdutoFromSerial(serial);
  if (idProduto == null) return null;
  final product = await db.getProduct(idProduto);
  final nome = product?.nome.trim();
  if (nome == null || nome.isEmpty) return null;
  return nome;
}

/// Tile de fila laser com serial e modelo a gravar.
class MarkQueueEntryTile extends ConsumerWidget {
  const MarkQueueEntryTile({
    required this.entry,
    required this.index,
    this.trailing,
    this.dateFmt,
    super.key,
  });

  final MarkQueueEntry entry;
  final int index;
  final Widget? trailing;
  final DateFormat? dateFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = dateFmt ?? DateFormat('dd/MM HH:mm');
    final inProgress = entry.status == 'in_progress';

    return FutureBuilder<String?>(
      future: resolveModelNameFromSerial(ref.read(databaseProvider), entry.serial),
      builder: (context, snapshot) {
        final modelName = snapshot.data;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: inProgress
              ? CircleAvatar(
                  radius: 14,
                  backgroundColor: DipontoColors.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.play_arrow, size: 16, color: DipontoColors.primary),
                )
              : entry.pinned
                  ? const Icon(Icons.push_pin, color: DipontoColors.primary)
                  : CircleAvatar(
                      radius: 14,
                      backgroundColor: DipontoColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DipontoColors.primary,
                        ),
                      ),
                    ),
          title: Text(
            entry.serial,
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            inProgress
                ? 'Em gravação · modelo ${modelName ?? '…'}'
                : 'Modelo ${modelName ?? '…'} · ${fmt.format(entry.createdAt)}',
          ),
          trailing: trailing,
        );
      },
    );
  }
}
