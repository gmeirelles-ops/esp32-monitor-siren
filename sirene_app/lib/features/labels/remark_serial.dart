import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/database/database.dart';
import '../labels/label_print_logic.dart';
import '../labels/label_printer.dart';
import '../labels/marking_providers.dart';
import '../labels/serial_marking_backend.dart';
import '../labels/zpl_generator.dart';
import '../mqtt/mqtt_providers.dart';
import '../operators/operators_provider.dart';

class RemarkUiCopy {
  const RemarkUiCopy({
    required this.actionLabel,
    required this.dialogTitle,
    required this.confirmLabel,
    required this.dialogBody,
    required this.icon,
    required this.successMessage,
  });

  final String actionLabel;
  final String dialogTitle;
  final String confirmLabel;
  final String dialogBody;
  final IconData icon;
  final String successMessage;
}

RemarkUiCopy remarkUiCopy(MarkingMode mode, String serial) {
  if (mode == MarkingMode.laser) {
    return RemarkUiCopy(
      actionLabel: 'Regravar',
      dialogTitle: 'Regravar serial',
      confirmLabel: 'Regravar',
      dialogBody:
          'O serial $serial será colocado na frente da fila de gravação laser. '
          'Acione F2 no DiatuCAD para gravar na carcaça.',
      icon: Icons.precision_manufacturing,
      successMessage: 'Serial $serial na fila — acione F2 no DiatuCAD',
    );
  }
  return RemarkUiCopy(
    actionLabel: 'Reimprimir',
    dialogTitle: 'Reimprimir etiqueta',
    confirmLabel: 'Reimprimir',
    dialogBody:
        'A impressora avançará uma linha inteira do rolo (3 posições). '
        'O serial $serial será impresso na primeira coluna; '
        'as outras duas saem em branco.',
    icon: Icons.print,
    successMessage: 'Etiqueta $serial reenviada à impressora',
  );
}

Future<bool> confirmRemark(
  BuildContext context,
  MarkingMode mode,
  String serial,
) async {
  final copy = remarkUiCopy(mode, serial);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(copy.dialogTitle),
      content: Text(copy.dialogBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(copy.confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<String?> executeRemark({
  required WidgetRef ref,
  required String serial,
  required String numeroOp,
}) async {
  final config = ref.read(appConfigProvider);
  final db = ref.read(databaseProvider);
  final operatorId = ref.read(sessionOperatorIdProvider);

  try {
    if (config.markingMode == MarkingMode.laser) {
      await ref.read(markQueueProcessorProvider).enqueueRemark(serial, numeroOp);
      await db.insertRemarkLog(
        serial: serial,
        numeroOp: numeroOp,
        mode: 'laser',
        operatorId: operatorId,
      );
      return remarkUiCopy(MarkingMode.laser, serial).successMessage;
    }

    final items = await resolveLabelZplItems(db, [serial]);
    final item = items.first;
    final printer = createLabelPrinterTransport(config);
    await printer.sendZpl(
      generateZplReprintRow(serial: item.serial, productName: item.productName),
    );
    await db.insertRemarkLog(
      serial: serial,
      numeroOp: numeroOp,
      mode: 'label',
      operatorId: operatorId,
    );
    return remarkUiCopy(MarkingMode.labels, serial).successMessage;
  } catch (e) {
    if (config.markingMode == MarkingMode.laser) {
      return formatMarkingError(e);
    }
    return formatPrinterError(e, config.printerMode);
  }
}

Future<void> remarkSerialIfConfirmed({
  required BuildContext context,
  required WidgetRef ref,
  required String serial,
  required String numeroOp,
}) async {
  final mode = ref.read(appConfigProvider).markingMode;
  if (!await confirmRemark(context, mode, serial)) return;
  if (!context.mounted) return;

  final message = await executeRemark(ref: ref, serial: serial, numeroOp: numeroOp);
  if (!context.mounted || message == null) return;

  final isError = message.contains('Erro') || message.contains('erro');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
  if (isError) return;
}
