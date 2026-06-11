import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import '../../features/mqtt/models/mqtt_messages.dart';
import '../../features/mqtt/mqtt_providers.dart';

class ConnectionStatusBadge extends ConsumerWidget {
  const ConnectionStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mqttConnectionStateProvider).value ??
        AppMqttConnectionState.disconnected;

    final (color, label) = switch (state) {
      AppMqttConnectionState.connected => (DipontoColors.success, 'MQTT OK'),
      AppMqttConnectionState.connecting => (DipontoColors.primaryLight, 'Conectando'),
      AppMqttConnectionState.reconnecting => (DipontoColors.primary, 'Reconectando'),
      AppMqttConnectionState.disconnected => (DipontoColors.error, 'Desconectado'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
