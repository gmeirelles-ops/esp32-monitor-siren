import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../mqtt/mqtt_providers.dart';
import 'demo_constants.dart';
import 'demo_playback.dart';
import 'demo_providers.dart';

/// Ativa o modo demonstração: bancada virtual, sem MQTT real.
Future<void> enableDemoMode(WidgetRef ref) async {
  final config = ref.read(appConfigProvider);
  await config.setDemoModeEnabled(true);
  await config.setSelectedDeviceId(kDemoDeviceId);
  await config.setBancadaSetupComplete(true);
  ref.read(devicesProvider.notifier).ensureDemoDevice(kDemoDeviceId);
  ref.invalidate(appConfigProvider);
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
