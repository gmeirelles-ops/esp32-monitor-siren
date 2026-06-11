import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mqtt/mqtt_providers.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _otaUrl = TextEditingController();
  String? _selectedDeviceId;
  String? _otaStatus;

  @override
  void dispose() {
    _otaUrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final deviceList = devices.values.toList();
    _selectedDeviceId ??= deviceList.isNotEmpty ? deviceList.first.deviceId : null;

    ref.listen(otaStreamProvider, (_, next) {
      next.whenData((ota) {
        setState(() => _otaStatus = 'OTA ${ota.evento}: ${ota.detalhe ?? ''}');
        _showSnack(_otaStatus!);
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (deviceList.isEmpty)
            const Text('Nenhum dispositivo disponível')
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedDeviceId,
              decoration: const InputDecoration(labelText: 'Dispositivo'),
              items: deviceList
                  .map((d) => DropdownMenuItem(value: d.deviceId, child: Text(d.deviceId)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDeviceId = v),
            ),
          const SizedBox(height: 24),
          const Text('Atualização OTA', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _otaUrl,
            decoration: const InputDecoration(
              labelText: 'URL do firmware (.bin)',
              hintText: 'http://192.168.1.10:8080/sirene-validator.bin',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _selectedDeviceId != null && _otaUrl.text.isNotEmpty
                ? () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar OTA'),
                        content: Text('Atualizar firmware de $_selectedDeviceId?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Atualizar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(devicesProvider.notifier)
                          .sendOtaUpdate(_selectedDeviceId!, _otaUrl.text.trim());
                    }
                  }
                : null,
            child: const Text('Enviar OTA_UPDATE'),
          ),
          if (_otaStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_otaStatus!, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
