import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../bancadas/bancadas_provider.dart';
import '../mqtt/mqtt_providers.dart';
import '../provisioning/provisioning_wizard.dart';

/// Setup inicial: vincula uma bancada ao posto (instalação do app).
class PostoSetupScreen extends ConsumerStatefulWidget {
  const PostoSetupScreen({super.key});

  @override
  ConsumerState<PostoSetupScreen> createState() => _PostoSetupScreenState();
}

class _PostoSetupScreenState extends ConsumerState<PostoSetupScreen> {
  String? _selectedDeviceId;
  bool _saving = false;

  Future<void> _confirm() async {
    final deviceId = _selectedDeviceId;
    if (deviceId == null) {
      _showSnack('Selecione uma bancada');
      return;
    }

    setState(() => _saving = true);
    try {
      final config = ref.read(appConfigProvider);
      await config.setSelectedDeviceId(deviceId);
      await config.setBancadaSetupComplete(true);
      ref.read(selectedDeviceIdProvider.notifier).state = deviceId;
      ref.invalidate(appConfigProvider);
      ref.invalidate(bancadaSetupCompleteProvider);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openProvisioning() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProvisioningWizard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final deviceList = devices.values.toList()
      ..sort((a, b) {
        final na = bancadas[a.deviceId] ?? 999999;
        final nb = bancadas[b.deviceId] ?? 999999;
        if (na != nb) return na.compareTo(nb);
        return a.deviceId.compareTo(b.deviceId);
      });

    _selectedDeviceId ??= ref.watch(selectedDeviceIdProvider) ??
        (deviceList.isNotEmpty ? deviceList.first.deviceId : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar posto')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Vincule este PC a uma bancada',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta escolha fica salva no posto. Para alterar depois, use Configurações → Manutenção do posto.',
            style: TextStyle(color: DipontoColors.primaryLight),
          ),
          const SizedBox(height: 24),
          if (deviceList.isEmpty) ...[
            const Icon(Icons.wifi_tethering, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Aguardando bancada na rede…',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Certifique-se de que o broker MQTT está acessível e que a bancada está ligada. '
              'Se for a primeira configuração, provisione o Wi-Fi do dispositivo.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openProvisioning,
              icon: const Icon(Icons.wifi),
              label: const Text('Assistente Wi-Fi'),
            ),
          ] else ...[
            Card(
              child: Column(
                children: [
                  for (final d in deviceList)
                    RadioListTile<String>(
                      value: d.deviceId,
                      groupValue: _selectedDeviceId,
                      onChanged: (v) => setState(() => _selectedDeviceId = v),
                      title: Text(formatBancadaLabelFromMap(d.deviceId, bancadas)),
                      subtitle: Text(d.isOnline ? 'Conectada' : 'Offline'),
                      secondary: Icon(
                        Icons.circle,
                        size: 10,
                        color: d.isOnline ? DipontoColors.success : DipontoColors.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openProvisioning,
                icon: const Icon(Icons.wifi),
                label: const Text('Provisionar Wi-Fi de uma bancada'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar bancada'),
            ),
          ],
        ],
      ),
    );
  }
}
