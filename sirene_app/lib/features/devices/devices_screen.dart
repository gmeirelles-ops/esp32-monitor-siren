import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/display_labels.dart';
import '../../shared/portuguese_labels.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/screen_page_layout.dart';
import '../../shared/widgets/section_intro.dart';
import '../../shared/widgets/status_chip_header.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import '../bancadas/bancadas_provider.dart';
import '../provisioning/provisioning_wizard.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final mqttState = resolveMqttConnectionDisplayState(
      ref.watch(mqttConnectionStateProvider),
      ref.read(mqttServiceProvider).currentState,
    );
    final mqttConnected = mqttState == AppMqttConnectionState.connected;
    final sorted = devices.values.toList()
      ..sort((a, b) {
        final na = a.bancadaNum ?? bancadas[a.deviceId] ?? 999999;
        final nb = b.bancadaNum ?? bancadas[b.deviceId] ?? 999999;
        if (na != nb) return na.compareTo(nb);
        return a.deviceId.compareTo(b.deviceId);
      });
    final onlineCount = sorted.where((d) => d.isOnline).length;

    final (emptyTitle, emptySubtitle, showProgress) = switch (mqttState) {
      AppMqttConnectionState.connected => (
          'Aguardando dispositivos...',
          'MQTT conectado. Nenhuma bancada publicou presença ainda.',
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
      appBar: screenAppBar(
        context,
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
      body: ScreenPageLayout(
        header: StatusChipHeader(
          chips: [
            StatusChipData(
              icon: Icons.podcasts_outlined,
              label: mqttConnected ? 'MQTT conectado' : 'MQTT offline',
              color: mqttConnected ? DipontoColors.success : DipontoColors.error,
            ),
            StatusChipData(
              icon: Icons.devices_outlined,
              label: '$onlineCount/${sorted.length} online',
              color: DipontoColors.primaryLight,
            ),
          ],
        ),
        intro: SectionIntro(
          title: PortugueseLabels.navBancadas,
          subtitle: 'Bancadas detectadas na rede MQTT. Toque para ver detalhes e firmware.',
          icon: Icons.precision_manufacturing_outlined,
        ),
        children: [
          if (sorted.isEmpty)
            EmptyStateView(
              icon: Icons.router,
              title: emptyTitle,
              subtitle: emptySubtitle,
              showProgress: showProgress,
            )
          else
            for (final device in sorted)
              _DeviceCard(device: device, bancadas: bancadas),
        ],
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
    final accent = device.isOnline ? DipontoColors.success : DipontoColors.error;

    return ActionSectionCard(
      icon: device.isOnline ? Icons.wifi : Icons.wifi_off,
      title: formatBancadaLabelForDevice(
        device.deviceId,
        bancadaNum: device.bancadaNum,
        numeros: bancadas,
      ),
      subtitle: '${device.estado.label}${device.isOnline ? ' · ${device.rssi} dBm' : ''}',
      accentColor: accent,
      trailing: const Icon(Icons.chevron_right),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isProvisioning)
            const Text(
              'Modo provisionamento — AP SireneValidator',
              style: TextStyle(color: DipontoColors.primaryLight),
            ),
          if (hasAlert)
            Text(
              'Alerta: ${device.lastHardwareAlert}',
              style: const TextStyle(color: DipontoColors.error),
            ),
          if (device.firmwareVersion.isNotEmpty)
            Text('Firmware ${device.firmwareVersion}'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ref.read(selectedDeviceIdProvider.notifier).state = device.deviceId;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DeviceDetailScreen(deviceId: device.deviceId),
                  ),
                );
              },
              child: const Text('Abrir detalhes'),
            ),
          ),
        ],
      ),
    );
  }
}
