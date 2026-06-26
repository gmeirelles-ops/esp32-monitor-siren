import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/factory_reset_service.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/responsive_field_row.dart';
import '../admin/admin_screen.dart';
import '../firmware/firmware_update_screen.dart';
import '../cloud/auth/auth_providers.dart';
import '../devices/devices_screen.dart';
import '../cloud/auth/login_screen.dart';
import '../operators/operators_provider.dart';
import '../cloud/firebase_bootstrap.dart';
import '../cloud/sync/sync_providers.dart';
import '../mqtt/mqtt_providers.dart';
import '../labels/label_printer.dart';
import '../labels/label_printer_transport.dart';
import '../labels/laser_diagnostics_panel.dart';
import '../labels/marking_providers.dart';
import '../labels/serial_marking_backend.dart';
import '../bancadas/bancadas_provider.dart';
import '../provisioning/provisioning_wizard.dart';
import 'serial_reconciliation_panel.dart';

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
  late final TextEditingController _laserTcpPort;
  late final TextEditingController _laserTcpCommand;
  PrinterMode _printerMode = PrinterMode.usb;
  MarkingMode _markingMode = MarkingMode.labels;
  String? _printerWindowsName;
  String? _bancadaDeviceId;
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
    _laserTcpPort = TextEditingController(text: '${config.laserTcpPort}');
    _laserTcpCommand = TextEditingController(text: config.laserTcpCommand);
    _markingMode = config.markingMode;
    _printerMode = Platform.isWindows ? config.printerMode : PrinterMode.network;
    _printerWindowsName = config.printerWindowsName.isEmpty ? null : config.printerWindowsName;
    _bancadaDeviceId = config.selectedDeviceId;
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
    _laserTcpPort.dispose();
    _laserTcpCommand.dispose();
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
    if (_markingMode == MarkingMode.laser && _laserTcpCommand.text.trim().isEmpty) {
      _showMessage(
        'Informe o comando TCP. Padrão recomendado: ${AppConfig.defaultLaserTcpCommand}',
      );
      return;
    }

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
    await config.setMarkingMode(_markingMode);
    await config.setLaserTcpPort(int.tryParse(_laserTcpPort.text) ?? AppConfig.defaultLaserTcpPort);
    final laserCommand = _laserTcpCommand.text.trim().isEmpty
        ? AppConfig.defaultLaserTcpCommand
        : _laserTcpCommand.text.trim();
    await config.setLaserTcpCommand(laserCommand);

    if (_markingMode == MarkingMode.laser) {
      ref.read(markQueueProcessorProvider).start();
    } else {
      ref.read(markQueueProcessorProvider).stop();
    }

    ref.invalidate(appConfigProvider);
    ref.read(devicesProvider.notifier).reconnect();
    ref.invalidate(syncStatusProvider);

    if (mounted) {
      if (_markingMode == MarkingMode.laser &&
          laserCommand != AppConfig.defaultLaserTcpCommand) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comando personalizado salvo. Confirme que o DiatuCAD usa exatamente: $laserCommand',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas')),
        );
      }
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
    final result = await pullCatalogDetailFromCloud(ref);
    if (!mounted) return;
    if (result.total == 0) {
      _showMessage('Nenhum produto ou operador na nuvem');
    } else {
      _showMessage(
        '${result.products} produto(s) e ${result.operators} operador(es) baixados',
      );
    }
  }

  Future<void> _saveBancada() async {
    final deviceId = _bancadaDeviceId;
    if (deviceId == null) {
      _showMessage('Selecione uma bancada');
      return;
    }
    final config = ref.read(appConfigProvider);
    await config.setSelectedDeviceId(deviceId);
    await config.setBancadaSetupComplete(true);
    ref.read(selectedDeviceIdProvider.notifier).state = deviceId;
    ref.invalidate(appConfigProvider);
    ref.invalidate(bancadaSetupCompleteProvider);
    if (mounted) _showMessage('Bancada vinculada ao posto');
  }

  Future<void> _openProvisioning() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProvisioningWizard()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _factoryReset() async {
    final confirmController = TextEditingController();
    var logoutFirebase = false;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reset geral do posto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Isso apaga todos os dados locais (SQLite, catálogo, histórico), '
                'remove o vínculo de bancada e marca o Wi-Fi como não provisionado. '
                'Digite ZERAR para confirmar.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(labelText: 'Confirmação'),
                autofocus: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sair da nuvem também'),
                subtitle: const Text('Encerra sessão Firebase (opcional)'),
                value: logoutFirebase,
                onChanged: (v) => setDialogState(() => logoutFirebase = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (confirmController.text.trim() != 'ZERAR') {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Digite ZERAR para confirmar')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Zerar posto'),
            ),
          ],
        ),
      ),
    );

    confirmController.dispose();
    if (proceed != true || !mounted) return;

    try {
      await ref.read(factoryResetServiceProvider).execute(logoutFirebase: logoutFirebase);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset concluído'),
          content: const Text(
            'Dados locais apagados. Feche e reabra o aplicativo, faça login '
            'e configure novamente a bancada e o Wi-Fi do posto.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      await clearOperatorSession(ref);
    } catch (e) {
      if (mounted) _showMessage('Erro no reset: $e');
    }
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

  Future<void> _testLaserMark() async {
    try {
      final processor = ref.read(markQueueProcessorProvider);
      await processor.enqueueTestSerial(AppConfig.laserTestSerial);
      await processor.ensureRunning();
      if (mounted) {
        _showMessage(
          'Serial ${AppConfig.laserTestSerial} enfileirado. '
          'Acione F2 no DiatuCAD para gravar.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(formatMarkingError(e));
      }
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
    final wifiProvisioned = ref.watch(wifiProvisionedProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final deviceList = devices.values.toList()
      ..sort((a, b) {
        final na = bancadas[a.deviceId] ?? 999999;
        final nb = bancadas[b.deviceId] ?? 999999;
        if (na != nb) return na.compareTo(nb);
        return a.deviceId.compareTo(b.deviceId);
      });
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
                  title: 'Manutenção do posto',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _bancadaDeviceId != null
                            ? 'Bancada: ${formatBancadaLabelFromMap(_bancadaDeviceId!, bancadas)}'
                            : 'Nenhuma bancada vinculada',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (deviceList.isEmpty)
                        const Text('Nenhuma bancada detectada na rede MQTT.')
                      else
                        DropdownButtonFormField<String>(
                          value: deviceList.any((d) => d.deviceId == _bancadaDeviceId)
                              ? _bancadaDeviceId
                              : null,
                          decoration: const InputDecoration(labelText: 'Bancada vinculada'),
                          items: [
                            for (final d in deviceList)
                              DropdownMenuItem(
                                value: d.deviceId,
                                child: Text(formatBancadaLabelFromMap(d.deviceId, bancadas)),
                              ),
                          ],
                          onChanged: (v) => setState(() => _bancadaDeviceId = v),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: deviceList.isEmpty ? null : _saveBancada,
                          child: const Text('Salvar bancada'),
                        ),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          wifiProvisioned ? Icons.wifi : Icons.wifi_off,
                          color: wifiProvisioned ? DipontoColors.success : Colors.grey,
                        ),
                        title: Text(wifiProvisioned ? 'Wi-Fi provisionado' : 'Wi-Fi não provisionado'),
                        subtitle: const Text('Assistente para conectar bancadas à rede da fábrica'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openProvisioning,
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Reconciliação de série',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const SerialReconciliationPanel(),
                      const Divider(height: 24),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: _factoryReset,
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: const Text('Reset geral do posto'),
                      ),
                    ],
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
                        leading: const Icon(Icons.system_update_alt),
                        title: const Text('Atualizar firmware'),
                        subtitle: const Text('OTA pela rede ou gravação USB'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const FirmwareUpdateScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.admin_panel_settings_outlined),
                        title: const Text('Administração'),
                        subtitle: const Text('Campanha OTA multi-bancada'),
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
                  title: 'Marcação de serial',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<MarkingMode>(
                        segments: const [
                          ButtonSegment(
                            value: MarkingMode.labels,
                            label: Text('Etiquetas (Zebra)'),
                            icon: Icon(Icons.label_outline),
                          ),
                          ButtonSegment(
                            value: MarkingMode.laser,
                            label: Text('Gravação laser (Diatu)'),
                            icon: Icon(Icons.precision_manufacturing),
                          ),
                        ],
                        selected: {_markingMode},
                        onSelectionChanged: (selection) {
                          setState(() => _markingMode = selection.first);
                        },
                      ),
                      if (_markingMode == MarkingMode.laser) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _laserTcpPort,
                          decoration: const InputDecoration(
                            labelText: 'Porta TCP (servidor no app)',
                            helperText:
                                'DiatuCAD conecta neste PC (127.0.0.1 se mesma máquina)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _laserTcpCommand,
                          decoration: InputDecoration(
                            labelText: 'Comando TCP esperado',
                            helperText:
                                'Igual ao configurado no texto variável do DiatuCAD '
                                '(padrão: ${AppConfig.defaultLaserTcpCommand})',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const LaserDiagnosticsPanel(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _testLaserMark,
                            icon: const Icon(Icons.bolt_outlined),
                            label: const Text('Testar gravação'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_markingMode == MarkingMode.labels)
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
