import 'package:flutter/material.dart';

import '../../../core/theme/diponto_theme.dart';
import '../../../shared/widgets/status_chip_header.dart';

class SettingsStatusHeader extends StatelessWidget {
  const SettingsStatusHeader({
    super.key,
    required this.operatorName,
    required this.mqttConnected,
    required this.bancadaLabel,
    required this.wifiProvisioned,
    required this.syncEnabled,
    required this.onlineBancadas,
    required this.totalBancadas,
  });

  final String operatorName;
  final bool mqttConnected;
  final String bancadaLabel;
  final bool wifiProvisioned;
  final bool syncEnabled;
  final int onlineBancadas;
  final int totalBancadas;

  @override
  Widget build(BuildContext context) {
    return StatusChipHeader(
      chips: [
        StatusChipData(icon: Icons.badge_outlined, label: operatorName, color: DipontoColors.primary),
        StatusChipData(
          icon: Icons.podcasts_outlined,
          label: mqttConnected ? 'MQTT conectado' : 'MQTT desconectado',
          color: mqttConnected ? DipontoColors.success : DipontoColors.error,
        ),
        StatusChipData(
          icon: Icons.precision_manufacturing_outlined,
          label: bancadaLabel,
          color: DipontoColors.primaryLight,
        ),
        StatusChipData(
          icon: wifiProvisioned ? Icons.wifi : Icons.wifi_off,
          label: wifiProvisioned ? 'Wi-Fi OK' : 'Wi-Fi pendente',
          color: wifiProvisioned ? DipontoColors.success : Colors.grey,
        ),
        StatusChipData(
          icon: Icons.devices_outlined,
          label: '$onlineBancadas/$totalBancadas bancadas',
          color: DipontoColors.primaryLight,
        ),
        StatusChipData(
          icon: syncEnabled ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          label: syncEnabled ? 'Sync ativo' : 'Sync desligado',
          color: syncEnabled ? DipontoColors.success : Colors.grey,
        ),
      ],
    );
  }
}
