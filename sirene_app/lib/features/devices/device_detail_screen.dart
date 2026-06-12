import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/diponto_app_bar.dart';
import '../mqtt/mqtt_providers.dart';

class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(devicesProvider)[deviceId];
    if (device == null) {
      return Scaffold(
        appBar: const DipontoAppBar(title: 'Dispositivo'),
        body: const Center(child: Text('Dispositivo não encontrado')),
      );
    }

    final lastSeen = device.lastSeen != null
        ? DateFormat('HH:mm:ss').format(device.lastSeen!)
        : '—';

    return Scaffold(
      appBar: DipontoAppBar(title: deviceId),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile('Presença', device.isOnline ? 'Online' : 'Offline'),
          _InfoTile('Estado FSM', device.estado.label),
          _InfoTile('RSSI', '${device.rssi} dBm'),
          _InfoTile('Uptime', '${device.uptime}s'),
          _InfoTile('Fila offline', '${device.fila}'),
          _InfoTile('Firmware', device.firmwareVersion.isEmpty ? '—' : device.firmwareVersion),
          _InfoTile('Último heartbeat', lastSeen),
          if (device.lastHardwareAlert != null)
            Card(
              color: DipontoColors.error.withValues(alpha: 0.15),
              child: ListTile(
                leading: const Icon(Icons.warning, color: DipontoColors.error),
                title: const Text('Falha de hardware'),
                subtitle: Text(device.lastHardwareAlert!),
              ),
            ),
          if (device.lastRejection != null)
            Card(
              color: DipontoColors.primary.withValues(alpha: 0.12),
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: DipontoColors.primary),
                title: const Text('Última rejeição MQTT'),
                subtitle: Text(device.lastRejection!.motivo),
              ),
            ),
          if (device.lastCalibration != null)
            _InfoTile('Última calibração', '${device.lastCalibration!.toStringAsFixed(2)} W'),
          if (device.lastTestResult != null) ...[
            const SizedBox(height: 16),
            const Text('Último teste', style: TextStyle(fontWeight: FontWeight.bold)),
            _InfoTile('Veredito', device.lastTestResult!.veredito),
            _InfoTile('Potência', '${device.lastTestResult!.potenciaMedia.toStringAsFixed(2)} W'),
            _InfoTile('Sequencial', '${device.lastTestResult!.sequencial}'),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: DipontoColors.primaryLight)),
          Text(value),
        ],
      ),
    );
  }
}
