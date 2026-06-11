import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/global_app_bar_actions.dart';
import '../mqtt/mqtt_providers.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _otaUrl = TextEditingController();
  final Set<String> _selectedDevices = {};
  String? _otaStatus;

  @override
  void dispose() {
    _otaUrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendCampaign() async {
    final targets = _selectedDevices.toList();
    if (targets.isEmpty || _otaUrl.text.trim().isEmpty) {
      _showSnack('Selecione ao menos um dispositivo e informe a URL');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar campanha OTA'),
        content: Text('Atualizar firmware de ${targets.length} dispositivo(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Atualizar')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(devicesProvider.notifier).sendOtaCampaign(targets, _otaUrl.text.trim());
    if (!mounted) return;
    _showSnack('OTA enviado para ${targets.length} dispositivo(s)');
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final deviceList = devices.values.toList();

    ref.listen(otaStreamProvider, (_, next) {
      next.whenData((ota) {
        setState(() => _otaStatus = 'OTA ${ota.evento}: ${ota.detalhe ?? ''}');
        _showSnack(_otaStatus!);
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: globalAppBarActions(),
      ),
      body: ListView(
        children: [
          DesktopFormLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSectionCard(
                  title: 'Campanha OTA',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _otaUrl,
                        decoration: const InputDecoration(
                          labelText: 'URL do firmware (.bin)',
                          hintText: 'http://192.168.1.10:8080/sirene-validator.bin',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (deviceList.isEmpty)
                        const Text('Nenhum dispositivo disponível')
                      else ...[
                        const Text(
                          'Dispositivos alvo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        for (final d in deviceList)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: _selectedDevices.contains(d.deviceId),
                            title: Text(d.deviceId),
                            subtitle: Text(d.estado.label),
                            onChanged: (checked) => setState(() {
                              if (checked == true) {
                                _selectedDevices.add(d.deviceId);
                              } else {
                                _selectedDevices.remove(d.deviceId);
                              }
                            }),
                          ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: _selectedDevices.isEmpty ? null : _sendCampaign,
                          child: Text(
                            'Enviar OTA para selecionados (${_selectedDevices.length})',
                          ),
                        ),
                      ),
                      if (_otaStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_otaStatus!, style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
