// Widget de referência — botão "Cancelar lote" na tela de Lote ou Configurações

import 'package:flutter/material.dart';

class BatchCancelButton extends StatelessWidget {
  const BatchCancelButton({
    super.key,
    required this.batchActive,
    required this.deviceOnline,
    required this.onCancel,
  });

  final bool batchActive;
  final bool deviceOnline;
  final Future<void> Function() onCancel;

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar lote'),
        content: const Text(
          'O lote ativo será encerrado no ESP32 e o dispositivo volta para IDLE.\n\n'
          'Use antes de calibrar produtos se o firmware antigo exigir IDLE.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar lote'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await onCancel();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lote cancelado — aguarde confirmação no status MQTT')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!batchActive) {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      onPressed: deviceOnline ? () => _confirm(context) : null,
      icon: const Icon(Icons.cancel_outlined),
      label: const Text('Cancelar lote'),
    );
  }
}
