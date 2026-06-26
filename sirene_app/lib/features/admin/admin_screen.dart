import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/global_app_bar_actions.dart';
import '../mqtt/mqtt_providers.dart';
import '../firmware/firmware_providers.dart';
import '../firmware/firmware_update_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _otaUrl = TextEditingController();
  final Set<String> _selectedDevices = {};
  String? _otaBinPath;
  String? _otaStatus;
  bool _showAdvancedUrl = false;
  bool _busy = false;

  @override
  void dispose() {
    _otaUrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickBin() async {
    const typeGroup = XTypeGroup(label: 'Firmware', extensions: ['bin']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    setState(() => _otaBinPath = file.path);
  }

  Future<void> _sendCampaignAssist() async {
    final targets = _selectedDevices.toList();
    if (targets.isEmpty || _otaBinPath == null) {
      _showSnack('Selecione dispositivos e arquivo .bin');
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

    final otaService = ref.read(otaAssistServiceProvider);
    final config = ref.read(appConfigProvider);
    setState(() => _busy = true);

    try {
      final url = await otaService.startServing(
        sourceBinPath: _otaBinPath!,
        mqttBrokerHost: config.mqttHost,
      );
      await ref.read(devicesProvider.notifier).sendOtaCampaign(targets, url);
      if (!mounted) return;
      _showSnack('OTA enviado para ${targets.length} dispositivo(s)');
      setState(() => _otaStatus = 'Servindo: $url');
    } catch (e) {
      _showSnack('$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _sendCampaignManualUrl() async {
    final targets = _selectedDevices.toList();
    if (targets.isEmpty || _otaUrl.text.trim().isEmpty) {
      _showSnack('Selecione dispositivos e informe a URL');
      return;
    }
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
                  title: 'Atualização simplificada',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Para uma bancada, use a tela dedicada com OTA e USB.',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const FirmwareUpdateScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.system_update_alt),
                        label: const Text('Abrir Atualizar firmware'),
                      ),
                    ],
                  ),
                ),
                FormSectionCard(
                  title: 'Campanha OTA (várias bancadas)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Arquivo .bin'),
                        subtitle: Text(_otaBinPath ?? 'Não selecionado'),
                        trailing: OutlinedButton(
                          onPressed: _busy ? null : _pickBin,
                          child: const Text('Escolher'),
                        ),
                      ),
                      if (deviceList.isEmpty)
                        const Text('Nenhum dispositivo disponível')
                      else ...[
                        const Text('Dispositivos alvo', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      ElevatedButton(
                        onPressed: _busy || _otaBinPath == null || _selectedDevices.isEmpty
                            ? null
                            : _sendCampaignAssist,
                        child: Text(
                          _busy
                              ? 'Preparando...'
                              : 'OTA assistido (${_selectedDevices.length} selecionados)',
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _showAdvancedUrl = !_showAdvancedUrl),
                        child: Text(_showAdvancedUrl ? 'Ocultar URL manual' : 'URL manual (avançado)'),
                      ),
                      if (_showAdvancedUrl) ...[
                        TextField(
                          controller: _otaUrl,
                          decoration: const InputDecoration(
                            labelText: 'URL externa do .bin',
                            hintText: 'http://192.168.51.70:8080/sirene-validator.bin',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _selectedDevices.isEmpty ? null : _sendCampaignManualUrl,
                          child: const Text('Enviar URL manual'),
                        ),
                      ],
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
