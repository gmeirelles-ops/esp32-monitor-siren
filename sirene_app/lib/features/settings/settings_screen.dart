import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/responsive_field_row.dart';
import '../admin/admin_screen.dart';
import '../cloud/auth/auth_providers.dart';
import '../devices/devices_screen.dart';
import '../cloud/auth/login_screen.dart';
import '../operators/operators_provider.dart';
import '../cloud/firebase_bootstrap.dart';
import '../cloud/sync/sync_providers.dart';
import '../mqtt/mqtt_providers.dart';
import '../labels/label_printer.dart';

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
  PrinterMode _printerMode = PrinterMode.usb;
  String? _printerWindowsName;
  List<String> _windowsPrinters = [];
  bool _loadingPrinters = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigProvider);
    _mqttHost = TextEditingController(text: config.mqttHost);
    _mqttPort = TextEditingController(text: '${config.mqttPort}');
    _printerHost = TextEditingController(text: config.printerHost);
    _printerPort = TextEditingController(text: '${config.printerPort}');
    _stationId = TextEditingController(text: config.stationId);
    _printerMode = Platform.isWindows ? config.printerMode : PrinterMode.network;
    _printerWindowsName = config.printerWindowsName.isEmpty ? null : config.printerWindowsName;
    if (Platform.isWindows) {
      _refreshWindowsPrinters();
    }
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

  Future<void> _refreshWindowsPrinters() async {
    if (!Platform.isWindows) return;
    setState(() => _loadingPrinters = true);
    final names = listWindowsPrinters();
    if (!mounted) return;
    setState(() {
      _windowsPrinters = names;
      _loadingPrinters = false;
      if (_printerWindowsName != null && !names.contains(_printerWindowsName)) {
        _printerWindowsName = names.isEmpty ? null : names.first;
      } else if (_printerWindowsName == null && names.isNotEmpty) {
        _printerWindowsName = names.first;
      }
    });
  }

  Future<void> _save() async {
    final config = ref.read(appConfigProvider);
    await config.setMqttHost(_mqttHost.text.trim());
    await config.setMqttPort(int.tryParse(_mqttPort.text) ?? 1883);
    await config.setPrinterMode(Platform.isWindows ? _printerMode : PrinterMode.network);
    await config.setPrinterHost(_printerHost.text.trim());
    await config.setPrinterPort(int.tryParse(_printerPort.text) ?? 9100);
    if (_printerWindowsName != null) {
      await config.setPrinterWindowsName(_printerWindowsName!);
    }
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
      _showMessage(firebaseUnavailableMessage);
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

  Future<void> _syncCatalog() async {
    if (!isFirebaseAvailable) {
      _showMessage(firebaseUnavailableMessage);
      return;
    }
    if (!ref.read(isAuthenticatedProvider) || !ref.read(syncEnabledProvider)) {
      _showMessage('Habilite o sync e faça login antes de enviar o catálogo.');
      return;
    }
    final count = await syncCatalogToCloud(ref);
    if (!mounted) return;
    _showMessage(
      count > 0
          ? '$count produto(s) enfileirado(s) para o Firestore'
          : 'Nenhum produto no catálogo local',
    );
  }

  Future<void> _pullCatalog() async {
    if (!isFirebaseAvailable) {
      _showMessage(firebaseUnavailableMessage);
      return;
    }
    if (!ref.read(isAuthenticatedProvider) || !ref.read(syncEnabledProvider)) {
      _showMessage('Habilite o sync e faça login antes de baixar o catálogo.');
      return;
    }
    final count = await pullCatalogFromCloud(ref);
    if (!mounted) return;
    _showMessage(
      count > 0
          ? '$count produto(s) baixado(s) da nuvem'
          : 'Nenhum produto na nuvem',
    );
  }

  Future<void> _logoutOperator() async {
    await clearOperatorSession(ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operador desconectado')),
      );
    }
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

  Future<void> _testPrint() async {
    try {
      final printer = createLabelPrinterTransportFromValues(
        mode: _printerMode,
        host: _printerHost.text.trim(),
        port: int.tryParse(_printerPort.text) ?? 9100,
        windowsName: _printerWindowsName ?? '',
      );
      await printer.sendZpl(kTestPrintZpl);
      if (mounted) {
        _showMessage('Etiqueta de teste enviada (${printer.modeDescription})');
      }
    } catch (e) {
      if (mounted) {
        _showMessage(formatPrinterError(e, _printerMode));
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _retryFailedSync({int? itemId}) async {
    await retryFailedSyncItems(ref, itemId: itemId);
    if (!mounted) return;
    _showMessage(
      itemId != null ? 'Item reenfileirado para sync' : 'Falhas reenfileiradas para sync',
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);
    final failedItems = ref.watch(failedSyncItemsProvider);
    final authenticated = ref.watch(isAuthenticatedProvider);
    final syncEnabled = ref.watch(syncEnabledProvider);
    final devices = ref.watch(devicesProvider);
    final activeOpAsync = ref.watch(activeOperatorProvider);
    final onlineCount = devices.values.where((d) => d.isOnline).length;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: screenAppBar(context, title: 'Configurações'),
      body: ListView(
        children: [
          DesktopFormLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSectionCard(
                  title: 'Operador',
                  child: activeOpAsync.when(
                    loading: () => const Text('Carregando...'),
                    error: (_, __) => const Text('Erro ao carregar operador'),
                    data: (op) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(op?.nome ?? '—'),
                          subtitle: op != null ? Text('PIN ${op.codigo}') : null,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _logoutOperator,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Trocar operador'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FormSectionCard(
                  title: 'Posto',
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.devices_outlined),
                        title: Text(PortugueseLabels.navBancadas),
                        subtitle: Text(
                          devices.isEmpty
                              ? 'Nenhuma bancada detectada'
                              : '$onlineCount de ${devices.length} conectadas',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DevicesScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.admin_panel_settings_outlined),
                        title: const Text('Administração (OTA)'),
                        subtitle: const Text('Firmware e comandos remotos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AdminScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                FormSectionCard(
                  title: 'Broker MQTT',
                  child: ResponsiveFieldRow(
                    flexes: const [7, 3],
                    children: [
                      TextField(
                        controller: _mqttHost,
                        decoration: const InputDecoration(labelText: 'Host'),
                      ),
                      TextField(
                        controller: _mqttPort,
                        decoration: const InputDecoration(labelText: 'Porta'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                FormSectionCard(
                  title: 'Impressora Zebra',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (Platform.isWindows)
                        SegmentedButton<PrinterMode>(
                          segments: const [
                            ButtonSegment(
                              value: PrinterMode.usb,
                              label: Text('USB (local)'),
                              icon: Icon(Icons.usb),
                            ),
                            ButtonSegment(
                              value: PrinterMode.network,
                              label: Text('Rede'),
                              icon: Icon(Icons.lan_outlined),
                            ),
                          ],
                          selected: {_printerMode},
                          onSelectionChanged: (selection) {
                            setState(() => _printerMode = selection.first);
                          },
                        )
                      else
                        const Text(
                          'Impressão USB disponível apenas no Windows. Usando modo rede.',
                          style: TextStyle(fontSize: 13),
                        ),
                      const SizedBox(height: 12),
                      if (_printerMode == PrinterMode.usb && Platform.isWindows) ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _windowsPrinters.contains(_printerWindowsName)
                                    ? _printerWindowsName
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Impressora Windows',
                                  helperText: 'ZT230 via USB com driver Zebra ZPL',
                                ),
                                items: [
                                  for (final name in _windowsPrinters)
                                    DropdownMenuItem(value: name, child: Text(name)),
                                ],
                                onChanged: _windowsPrinters.isEmpty
                                    ? null
                                    : (value) => setState(() => _printerWindowsName = value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Atualizar lista',
                              onPressed: _loadingPrinters ? null : _refreshWindowsPrinters,
                              icon: _loadingPrinters
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ] else ...[
                        ResponsiveFieldRow(
                          flexes: const [7, 3],
                          children: [
                            TextField(
                              controller: _printerHost,
                              decoration: const InputDecoration(labelText: 'IP'),
                            ),
                            TextField(
                              controller: _printerPort,
                              decoration: const InputDecoration(labelText: 'Porta (padrão 9100)'),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _testPrint,
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Testar impressão'),
                        ),
                      ),
                    ],
                  ),
                ),
                FormSectionCard(
                  title: 'Nuvem (Firestore)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isFirebaseAvailable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            firebaseUnavailableMessage,
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
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
                        contentPadding: EdgeInsets.zero,
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
                      failedItems.when(
                        data: (items) {
                          if (items.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                'Fila com falha',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              for (final item in items)
                                Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      item.documentPath ??
                                          '${item.collection}/${item.documentId}',
                                    ),
                                    subtitle: Text(
                                      item.lastError ?? 'Erro desconhecido',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: TextButton(
                                      onPressed: () => _retryFailedSync(itemId: item.id),
                                      child: const Text('Tentar novamente'),
                                    ),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton(
                                  onPressed: () => _retryFailedSync(),
                                  child: const Text('Reprocessar todas as falhas'),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      if (isFirebaseAvailable && syncEnabled && authenticated) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: _syncCatalog,
                            child: const Text('Enviar catálogo para Firestore'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: _pullCatalog,
                            child: const Text('Baixar catálogo da nuvem'),
                          ),
                        ),
                      ],
                      if (authenticated) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: _logout,
                            child: const Text('Sair da conta nuvem'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Salvar'),
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
