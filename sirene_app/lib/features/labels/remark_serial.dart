import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../shared/widgets/app_message.dart';
import '../labels/laser_mark_callout.dart';
import '../labels/laser_operator_copy.dart';
import '../labels/mark_queue_ui.dart';
import '../labels/marking_providers.dart';
import '../labels/serial_marking_backend.dart';
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

RemarkUiCopy remarkUiCopy(String serial) {
  return RemarkUiCopy(
    actionLabel: 'Regravar',
    dialogTitle: 'Regravar serial',
    confirmLabel: 'Regravar',
    dialogBody: LaserOperatorCopy.remarkDialogBody(serial),
    icon: Icons.precision_manufacturing,
    successMessage: LaserOperatorCopy.enqueuedSnack(serial),
  );
}

bool remarkRequiresConfirmation() => false;

Future<bool> confirmRemark(
  BuildContext context,
  String serial,
) async {
  final copy = remarkUiCopy(serial);
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
  final db = ref.read(databaseProvider);
  final operatorId = ref.read(sessionOperatorIdProvider);

  try {
    await ref.read(markQueueProcessorProvider).enqueueRemark(serial, numeroOp);
    await db.insertRemarkLog(
      serial: serial,
      numeroOp: numeroOp,
      mode: 'laser',
      operatorId: operatorId,
    );
    return remarkUiCopy(serial).successMessage;
  } catch (e) {
    return formatMarkingError(e);
  }
}

Future<void> remarkSerialIfConfirmed({
  required BuildContext context,
  required WidgetRef ref,
  required String serial,
  required String numeroOp,
}) async {
  if (remarkRequiresConfirmation()) {
    if (!await confirmRemark(context, serial)) return;
  }
  if (!context.mounted) return;

  final message = await executeRemark(ref: ref, serial: serial, numeroOp: numeroOp);
  if (!context.mounted || message == null) return;

  final isError = message.contains('Erro') || message.contains('erro');
  if (isError) {
    showAppMessage(context, message, kind: AppMessageKind.error);
    return;
  }

  final modelo = await resolveModelNameFromSerial(ref.read(databaseProvider), serial);
  if (!context.mounted) return;
  showLaserEnqueuedFeedback(context, serial: serial, modelo: modelo);
}
