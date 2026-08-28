import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../cloud/sync/sync_providers.dart';
import '../mqtt/mqtt_providers.dart';
import '../operators/operators_provider.dart';
import '../products/products_provider.dart';
import 'demo_constants.dart';
import 'demo_playback.dart';
import 'demo_providers.dart';
import 'demo_seed.dart';

Future<void> _applyDemoPreferences(WidgetRef ref) async {
  final config = ref.read(appConfigProvider);
  await config.setDemoModeEnabled(true);
  await config.setSelectedDeviceId(kDemoDeviceId);
  await config.setBancadaSetupComplete(true);
  await config.setStationId(kDemoStationId);
  await config.setSyncEnabled(false);
  await config.setCloudSetupComplete(true);
  await config.setCloudSyncNeedsAttention(false);
  ref.read(selectedDeviceIdProvider.notifier).state = kDemoDeviceId;
  ref.read(syncEnabledProvider.notifier).state = false;
}

void _invalidateDemoProviders(WidgetRef ref) {
  ref.invalidate(appConfigProvider);
  ref.invalidate(bancadaSetupCompleteProvider);
  ref.invalidate(cloudSetupCompleteProvider);
  ref.invalidate(activeOperatorsStreamProvider);
  ref.invalidate(productsStreamProvider);
}

/// Ativa o modo demonstração: bancada virtual, sem MQTT real.
Future<void> enableDemoMode(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  await seedDemoEnvironment(db);
  await _applyDemoPreferences(ref);
  ref.read(devicesProvider.notifier).ensureDemoDevice(kDemoDeviceId);
  _invalidateDemoProviders(ref);
}

/// Entrada rápida na tela de login — seed, configura posto virtual e autentica.
Future<void> enterDemoModeFromLogin(
  WidgetRef ref, {
  bool asGestor = true,
}) async {
  final db = ref.read(databaseProvider);
  final seed = await seedDemoEnvironment(db);
  await _applyDemoPreferences(ref);
  ref.read(devicesProvider.notifier).ensureDemoDevice(kDemoDeviceId);
  final operatorId = asGestor ? seed.gestorId : seed.operadorId;
  await setActiveOperator(ref, operatorId);
  _invalidateDemoProviders(ref);
}

/// Desativa demo e para autoplay.
Future<void> disableDemoMode(WidgetRef ref) async {
  ref.read(demoPlaybackProvider).stop();
  await ref.read(appConfigProvider).setDemoModeEnabled(false);
  ref.invalidate(appConfigProvider);
}

/// Resolve o deviceId efetivo (demo ou bancada real).
String? resolveActiveDeviceId(WidgetRef ref) {
  if (ref.read(demoModeProvider)) return kDemoDeviceId;
  return ref.read(selectedDeviceIdProvider) ?? ref.read(appConfigProvider).selectedDeviceId;
}

/// Resolve o deviceId efetivo (versão Ref).
String? resolveActiveDeviceIdFromRef(Ref ref) {
  if (ref.read(demoModeProvider)) return kDemoDeviceId;
  return ref.read(selectedDeviceIdProvider) ?? ref.read(appConfigProvider).selectedDeviceId;
}
