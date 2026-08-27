// Copiar/adaptar para sirene_app — widget em Configurações → Dispositivo

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wifi_reset_service.dart';

class WifiChangeSection extends StatelessWidget {
  const WifiChangeSection({
    super.key,
    required this.deviceId,
    required this.wifiSsid,
    required this.isOnline,
    required this.onResetRequested,
  });

  final String deviceId;
  final String? wifiSsid;
  final bool isOnline;
  final Future<void> Function({bool clearMqtt}) onResetRequested;

  Future<void> _confirmAndReset(BuildContext context) async {
    final clearMqtt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar Wi-Fi'),
        content: const Text(
          'O dispositivo vai reiniciar e abrir a rede SireneValidator (senha: sirene123).\n\n'
          'Depois conecte este PC à rede SireneValidator e configure em '
          'http://192.168.4.1\n\n'
          'Apagar também o broker MQTT salvo no dispositivo?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Manter MQTT')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar MQTT')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ],
      ),
    );
    if (clearMqtt == null || !context.mounted) return;
    await onResetRequested(clearMqtt: clearMqtt);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset enviado — aguarde o AP SireneValidator')),
    );
  }

  Future<void> _openPortal() async {
    final uri = Uri.parse(WifiResetService.portalUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o portal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wi-Fi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(wifiSsid?.isNotEmpty == true ? 'Rede: $wifiSsid' : 'Rede: —'),
            const SizedBox(height: 12),
            if (isOnline)
              FilledButton.icon(
                onPressed: () => _confirmAndReset(context),
                icon: const Icon(Icons.wifi_find),
                label: const Text('Alterar Wi-Fi (via MQTT)'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openPortal,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Abrir portal (192.168.4.1)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Sem MQTT: segure o botão de teste no ESP32 por 5 segundos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
