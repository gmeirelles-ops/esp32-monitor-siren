import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_category.dart';

/// Categoria de Configurações a abrir quando o gestor toca no badge de nuvem.
final settingsCategoryRequestProvider = StateProvider<SettingsCategory?>((ref) => null);

/// Aba do shell a selecionar (rótulo ex.: `Configurações`, `Relatório`).
final appShellTabRequestProvider = StateProvider<String?>((ref) => null);

void requestSettingsCategory(WidgetRef ref, SettingsCategory category) {
  ref.read(settingsCategoryRequestProvider.notifier).state = category;
  ref.read(appShellTabRequestProvider.notifier).state = 'Configurações';
}

void requestAppShellTab(WidgetRef ref, String label) {
  ref.read(appShellTabRequestProvider.notifier).state = label;
}
