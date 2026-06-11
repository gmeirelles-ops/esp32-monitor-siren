import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../cloud/auth/auth_providers.dart';
import '../cloud/auth/login_screen.dart';
import '../cloud/firebase_bootstrap.dart';
import '../cloud/sync/sync_providers.dart';
import '../mqtt/mqtt_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _mqttHost;
  late final TextEditingController _mqttPort;
  late final TextEditingController _printerHost;
  late final TextEditingController _printerPort;
  late final TextEditingController _stationId;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigProvider);
    _mqttHost = TextEditingController(text: config.mqttHost);
    _mqttPort = TextEditingController(text: '${config.mqttPort}');
    _printerHost = TextEditingController(text: config.printerHost);
    _printerPort = TextEditingController(text: '${config.printerPort}');
    _stationId = TextEditingController(text: config.stationId);
  }

  @override
  void dispose() {
    _mqttHost.dispose();
    _mqttPort.dispose();
    _printerHost.dispose();
    _printerPort.dispose();
    _stationId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final config = ref.read(appConfigProvider);
    await config.setMqttHost(_mqttHost.text.trim());
    await config.setMqttPort(int.tryParse(_mqttPort.text) ?? 1883);
    await config.setPrinterHost(_printerHost.text.trim());
    await config.setPrinterPort(int.tryParse(_printerPort.text) ?? 9100);
    await config.setStationId(_stationId.text.trim().isEmpty
        ? AppConfig.defaultStationId
        : _stationId.text.trim());

    ref.read(devicesProvider.notifier).reconnect();
    ref.invalidate(syncStatusProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas')),
      );
    }
  }

  Future<void> _onSyncToggle(bool? value) async {
    if (value != true) {
      await setSyncEnabled(ref, false);
      return;
    }

    if (!isFirebaseAvailable) {
      _showMessage('Firebase não configurado. Execute flutterfire configure.');
      return;
    }

    final authenticated = ref.read(isAuthenticatedProvider);
    if (!authenticated) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const LoginScreen()),
      );
      if (ok != true || !ref.read(isAuthenticatedProvider)) return;
    }

    await setSyncEnabled(ref, true);
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider)?.signOut();
    await setSyncEnabled(ref, false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão encerrada')),
      );
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);
    final authenticated = ref.watch(isAuthenticatedProvider);
    final syncEnabled = ref.watch(syncEnabledProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Broker MQTT', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _mqttHost,
            decoration: const InputDecoration(labelText: 'Host'),
          ),
          TextField(
            controller: _mqttPort,
            decoration: const InputDecoration(labelText: 'Porta'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text('Impressora Zebra', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _printerHost,
            decoration: const InputDecoration(labelText: 'IP'),
          ),
          TextField(
            controller: _printerPort,
            decoration: const InputDecoration(labelText: 'Porta (padrão 9100)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text('Nuvem (Firestore)', style: TextStyle(fontWeight: FontWeight.bold)),
          if (!isFirebaseAvailable)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Firebase não configurado neste build. Operação local disponível.',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
              ),
            ),
          TextField(
            controller: _stationId,
            decoration: const InputDecoration(
              labelText: 'ID do posto (station_id)',
              helperText: 'Identifica este PC na nuvem',
            ),
          ),
          SwitchListTile(
            title: const Text('Sincronizar com Firestore'),
            subtitle: Text(
              authenticated
                  ? 'Operador autenticado'
                  : 'Login necessário para habilitar',
            ),
            value: syncEnabled,
            onChanged: isFirebaseAvailable ? _onSyncToggle : null,
          ),
          syncStatus.when(
            data: (status) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pendentes: ${status.pending}'),
                Text('Falhas permanentes: ${status.failed}'),
                Text(
                  status.lastSync != null
                      ? 'Último sync: ${dateFmt.format(status.lastSync!.toLocal())}'
                      : 'Último sync: —',
                ),
              ],
            ),
            loading: () => const Text('Carregando status da fila...'),
            error: (e, _) => Text('Erro ao ler fila: $e'),
          ),
          if (authenticated) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _logout,
              child: const Text('Sair da conta nuvem'),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('Salvar')),
        ],
      ),
    );
  }
}
