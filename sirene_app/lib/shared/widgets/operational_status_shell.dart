import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/mqtt/models/mqtt_messages.dart';
import '../../features/mqtt/mqtt_providers.dart';

/// Banner global apenas para MQTT desconectado.
/// Sync Firestore roda em background (~1 min) — sem aviso de fila pendente.
class OperationalStatusShell extends ConsumerStatefulWidget {
  const OperationalStatusShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OperationalStatusShell> createState() => _OperationalStatusShellState();
}

class _OperationalStatusShellState extends ConsumerState<OperationalStatusShell> {
  bool _mqttBannerVisible = false;

  void _hideMqttBanner() {
    setState(() => _mqttBannerVisible = false);
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }

  void _showMqttBanner(String message) {
    if (_mqttBannerVisible) return;
    _mqttBannerVisible = true;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        leading: const Icon(Icons.podcasts_outlined, color: Colors.orangeAccent),
        backgroundColor: Colors.orange.withValues(alpha: 0.12),
        actions: [
          TextButton(onPressed: _hideMqttBanner, child: const Text('Dispensar')),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialMqtt());
  }

  void _checkInitialMqtt() {
    if (!mounted) return;
    final mqttService = ref.read(mqttServiceProvider);
    final streamState = ref.read(mqttConnectionStateProvider);
    final state = resolveMqttConnectionDisplayState(streamState, mqttService.currentState);
    if (state != AppMqttConnectionState.connected) {
      _showMqttBanner('Sem conexão com a bancada — verifique a rede do posto.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqttService = ref.watch(mqttServiceProvider);

    ref.listen<AsyncValue<AppMqttConnectionState>>(mqttConnectionStateProvider, (prev, next) {
      final state = resolveMqttConnectionDisplayState(next, mqttService.currentState);
      if (state == AppMqttConnectionState.disconnected ||
          state == AppMqttConnectionState.reconnecting) {
        final err = mqttService.lastConnectError;
        _showMqttBanner(
          err != null && err.isNotEmpty
              ? 'Sem conexão com a bancada: $err'
              : 'Sem conexão com a bancada — resultados não chegam até reconectar.',
        );
      } else if (state == AppMqttConnectionState.connected) {
        if (_mqttBannerVisible) _hideMqttBanner();
      }
    });

    return widget.child;
  }
}
