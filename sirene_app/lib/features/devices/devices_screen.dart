import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/connection_status.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final sorted = devices.values.toList()
      ..sort((a, b) => a.deviceId.compareTo(b.deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: ConnectionStatusBadge()),
          ),
        ],
      ),
      body: sorted.isEmpty
          ? const EmptyStateView(
              icon: Icons.router,
              title: 'Aguardando dispositivos...',
              subtitle: 'Conecte-se ao broker MQTT nas Configurações.',
              showProgress: true,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final device = sorted[index];
                return _DeviceCard(device: device);
              },
            ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device});

  final DeviceInfo device;

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
        title: Text(device.deviceId, style: const TextStyle(fontFamily: 'monospace')),
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
