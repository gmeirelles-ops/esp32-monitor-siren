import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';

/// Modo demonstração ativo (persistido em SharedPreferences).
final demoModeProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).demoModeEnabled;
});

/// Autoplay de testes simulados no painel ao vivo.
final demoAutoPlayProvider = StateProvider<bool>((ref) => false);
