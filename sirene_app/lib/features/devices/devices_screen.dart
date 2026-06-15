import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/display_labels.dart';
import '../../shared/portuguese_labels.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../bancadas/bancadas_provider.dart';
import '../provisioning/provisioning_wizard.dart';
import '../../shared/widgets/diponto_app_bar.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final mqttState = ref.watch(mqttConnectionStateProvider).value ??
        AppMqttConnectionState.disconnected;
    final sorted = devices.values.toList()
      ..sort((a, b) {
        final na = bancadas[a.deviceId] ?? 999999;
        final nb = bancadas[b.deviceId] ?? 999999;
        if (na != nb) return na.compareTo(nb);
        return a.deviceId.compareTo(b.deviceId);
      });

    final (emptyTitle, emptySubtitle, showProgress) = switch (mqttState) {
      AppMqttConnectionState.connected => (
          'Aguardando dispositivos...',
          'MQTT conectado. Nenhuma sirene publicou presença ainda.',
          true,
        ),
      AppMqttConnectionState.connecting ||
      AppMqttConnectionState.reconnecting => (
          'Conectando ao broker MQTT...',
          'Verifique host e porta em Configurações.',
          true,
        ),
      AppMqttConnectionState.disconnected => (
          'Broker MQTT desconectado',
          'Configure o broker em Configurações e toque em Salvar.',
          false,
        ),
    };

    return Scaffold(
      appBar: DipontoAppBar(
        title: PortugueseLabels.navBancadas,
        actions: [
          IconButton(
            tooltip: 'Provisionamento Wi-Fi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProvisioningWizard()),
              );
            },
            icon: const Icon(Icons.wifi),
          ),
        ],
      ),
      body: sorted.isEmpty
          ? EmptyStateView(
              icon: Icons.router,
              title: emptyTitle,
              subtitle: emptySubtitle,
              showProgress: showProgress,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final device = sorted[index];
                return _DeviceCard(device: device, bancadas: bancadas);
              },
            ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device, required this.bancadas});

  final DeviceInfo device;
  final Map<String, int> bancadas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProvisioning = device.estado == DeviceFsmState.provisioning;
    final hasAlert = device.lastHardwareAlert != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isOnline ? DipontoColors.success : DipontoColors.error,
          child: Icon(
            device.isOnline ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(formatBancadaLabelFromMap(device.deviceId, bancadas)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.estado.label),
            if (isProvisioning)
              const Text(
                'Provisionando',
                style: TextStyle(color: DipontoColors.primaryLight),
              ),
            if (hasAlert)
              Text(
                'Alerta: ${device.lastHardwareAlert}',
                style: const TextStyle(color: DipontoColors.error),
              ),
          ],
        ),
        trailing: device.isOnline
            ? Text('${device.rssi} dBm', style: const TextStyle(fontSize: 12))
            : null,
        onTap: () {
          ref.read(selectedDeviceIdProvider.notifier).state = device.deviceId;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DeviceDetailScreen(deviceId: device.deviceId),
            ),
          );
        },
      ),
    );
  }
}
