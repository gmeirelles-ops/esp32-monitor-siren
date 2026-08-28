import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/operators/operators_provider.dart';

/// Botão padrão para voltar à seleção de operador (gestor e operador).
class OperatorSwitchButton extends ConsumerWidget {
  const OperatorSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Trocar operador',
      onPressed: () => clearOperatorSession(ref),
      icon: const Icon(Icons.swap_horiz),
    );
  }
}
