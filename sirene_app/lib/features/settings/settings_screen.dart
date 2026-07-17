import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/factory_reset_service.dart';
import '../../core/services/app_log.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/display_labels.dart';
import '../../shared/dropdown_value.dart';
import '../../shared/portuguese_labels.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/responsive_field_row.dart';
import '../admin/admin_screen.dart';
import '../firmware/firmware_update_screen.dart';
import '../cloud/auth/auth_providers.dart';
import '../devices/devices_screen.dart';
import '../cloud/auth/login_screen.dart';
import '../operators/operators_provider.dart';
import '../cloud/firebase_bootstrap.dart';
import '../cloud/sync/sync_payload_repair.dart';
import '../cloud/sync/sync_providers.dart';
import '../demo/demo_constants.dart';
import '../demo/demo_providers.dart';
import '../demo/demo_service.dart';
import '../ensaio/ensaio_screen.dart';
import '../mqtt/mqtt_providers.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../labels/label_printer.dart';
import '../labels/laser_diagnostics_panel.dart';
import '../labels/marking_providers.dart';
import '../labels/serial_marking_backend.dart';
import '../dashboard/dashboard_providers.dart';
import '../bancadas/bancadas_provider.dart';
import '../provisioning/provisioning_constants.dart';
import '../provisioning/provisioning_wizard.dart';
import 'serial_reconciliation_panel.dart';
import 'settings_category.dart';
import 'widgets/settings_category_nav.dart';
import 'widgets/settings_action_card.dart';
import 'panels/settings_nuvem_panel.dart';
import 'widgets/settings_section_intro.dart';
import 'widgets/settings_status_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _mqttHost;
  late final TextEditingController _mqttPort;
  late final TextEditingController _mqttSite;
  late final TextEditingController _mqttWsPath;
  late final TextEditingController _mqttUsername;
  late final TextEditingController _mqttPassword;
  bool _mqttUseWebSocket = AppConfig.defaultMqttUseWebSocket;
  bool _mqttUseTls = AppConfig.defaultMqttUseTls;
  bool _mqttPasswordVisible = false;
  late final TextEditingController _printerHost;
  late final TextEditingController _printerPort;
  late final TextEditingController _stationId;
  late final TextEditingController _laserTcpPort;
  late final TextEditingController _laserTcpCommand;
  late final TextEditingController _laserModelCommand;
  PrinterMode _printerMode = PrinterMode.usb;
  MarkingMode _markingMode = MarkingMode.laser;
  String? _printerWindowsName;
  String? _bancadaDeviceId;
  List<String> _windowsPrinters = [];
  bool _loadingPrinters = false;
  late double _yieldTargetPct;
  late int _shiftStartHour;
  SettingsCategory _selectedCategory = SettingsCategory.posto;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigProvider);
    _mqttHost = TextEditingController(text: config.mqttHost);
    _mqttPort = TextEditingController(text: '${config.mqttPort}');
    _mqttSite = TextEditingController(text: config.mqttSite);
    _mqttWsPath = TextEditingController(text: config.mqttWebSocketPath);
    _mqttUsername = TextEditingController(text: config.mqttUsername);
    _mqttPassword = TextEditingController(text: config.mqttPassword);
    _mqttUseWebSocket = config.mqttUseWebSocket;
    _mqttUseTls = config.mqttUseTls;
    _printerHost = TextEditingController(text: config.printerHost);
    _printerPort = TextEditingController(text: '${config.printerPort}');
    _stationId = TextEditingController(text: config.stationId);
    _laserTcpPort = TextEditingController(text: '${config.laserTcpPort}');
    _laserTcpCommand = TextEditingController(text: config.laserTcpCommand);
    _laserModelCommand = TextEditingController(text: config.laserModelCommand);
    _markingMode = config.markingMode;
    _printerMode = Platform.isWindows
        ? config.printerMode
        : PrinterMode.network;
    _printerWindowsName = config.printerWindowsName.isEmpty
        ? null
        : config.printerWindowsName;
    _bancadaDeviceId = config.selectedDeviceId;
    _yieldTargetPct = config.yieldTargetPct;
    _shiftStartHour = config.shiftStartHour;
    if (Platform.isWindows) {
      _refreshWindowsPrinters();
    }
  }

  @override
  void dispose() {
    _mqttHost.dispose();
    _mqttPort.dispose();
    _mqttSite.dispose();
    _mqttWsPath.dispose();
    _mqttUsername.dispose();
    _mqttPassword.dispose();
    _printerHost.dispose();
    _printerPort.dispose();
    _stationId.dispose();
    _laserTcpPort.dispose();
    _laserTcpCommand.dispose();
    _laserModelCommand.dispose();
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
    if (_laserTcpCommand.text.trim().isEmpty) {
      _showMessage(
        'Informe o comando TCP. Padrão recomendado: ${AppConfig.defaultLaserTcpCommand}',
      );
      return;
    }
    if (_laserModelCommand.text.trim().isEmpty) {
      _showMessage(
        'Informe o comando TCP do modelo. Padrão recomendado: ${AppConfig.defaultLaserModelCommand}',
      );
      return;
    }
    final laserCommands = {
      _laserTcpCommand.text.trim(),
      _laserModelCommand.text.trim(),
    };
    if (laserCommands.length != 2) {
      _showMessage(
        'Os comandos TCP do serial e do modelo devem ser diferentes.',
      );
      return;
    }

    final stationId = AppConfig.normalizeStationId(_stationId.text);
    if (!AppConfig.isValidStationId(stationId)) {
      _showMessage(
        'ID do posto inválido. Use letras, números, hífen ou underscore (ex.: posto-01).',
      );
      return;
    }

    final config = ref.read(appConfigProvider);
    await config.setMqttHost(_mqttHost.text.trim());
    await config.setMqttPort(
      int.tryParse(_mqttPort.text) ?? AppConfig.defaultMqttPort,
    );
    await config.setMqttSite(_mqttSite.text.trim());
    await config.setMqttWebSocketPath(
      _mqttWsPath.text.trim().isEmpty
          ? AppConfig.defaultMqttWebSocketPath
          : _mqttWsPath.text.trim(),
    );
    await config.setMqttUseWebSocket(_mqttUseWebSocket);
    await config.setMqttUseTls(_mqttUseTls);
    await config.setMqttUsername(_mqttUsername.text.trim());
    await config.setMqttPassword(_mqttPassword.text);
    await config.setPrinterMode(
      Platform.isWindows ? _printerMode : PrinterMode.network,
    );
    await config.setPrinterHost(_printerHost.text.trim());
    await config.setPrinterPort(int.tryParse(_printerPort.text) ?? 9100);
    if (_printerWindowsName != null) {
      await config.setPrinterWindowsName(_printerWindowsName!);
    }
    await config.setStationId(stationId);
    await config.setMarkingMode(MarkingMode.laser);
    await config.setLaserTcpPort(
      int.tryParse(_laserTcpPort.text) ?? AppConfig.defaultLaserTcpPort,
    );
    final laserCommand = _laserTcpCommand.text.trim().isEmpty
        ? AppConfig.defaultLaserTcpCommand
        : _laserTcpCommand.text.trim();
    await config.setLaserTcpCommand(laserCommand);
    final laserModelCommand = _laserModelCommand.text.trim().isEmpty
        ? AppConfig.defaultLaserModelCommand
        : _laserModelCommand.text.trim();
    await config.setLaserModelCommand(laserModelCommand);
    await config.setYieldTargetPct(_yieldTargetPct);
    await config.setShiftStartHour(_shiftStartHour);

    ref.read(markQueueProcessorProvider).start();

    ref.invalidate(appConfigProvider);
    ref.read(devicesProvider.notifier).reconnect();
    ref.invalidate(syncStatusProvider);

    if (ref.read(syncEnabledProvider) && ref.read(isAuthenticatedProvider)) {
      try {
        final db = ref.read(databaseProvider);
        final repaired = await repairSyncQueuePayloads(db, stationId);
        if (repaired > 0) {
          await AppLog.write(
            'Sync: corrigiu station_id em $repaired item(ns) ao salvar posto',
          );
        }
        ensureSyncProcessorRunning(ref);
        await ref.read(syncQueueProcessorProvider).processQueue();
        ref.invalidate(syncStatusProvider);
        ref.invalidate(failedSyncItemsProvider);
      } catch (e, st) {
        await AppLog.write(
          'Sync: processQueue após salvar posto falhou',
          error: e,
          stack: st,
        );
      }
    }

    if (mounted) {
      if (laserCommand != AppConfig.defaultLaserTcpCommand ||
          laserModelCommand != AppConfig.defaultLaserModelCommand) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comandos salvos. Confirme no DiatuCAD: serial="$laserCommand", modelo="$laserModelCommand"',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Configurações salvas')));
      }
    }
  }

  Future<void> _registerDowntime() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Registrar parada'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Motivo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    await ref
        .read(databaseProvider)
        .insertDowntime(
          reason: reason,
          deviceId: ref.read(appConfigProvider).selectedDeviceId,
        );
    ref.read(localDataRevisionProvider.notifier).state++;
    _showMessage('Parada registrada');
  }

  Future<void> _onSyncToggle(bool? value) async {
    try {
      if (value != true) {
        final cloudReady = ref.read(cloudSetupCompleteProvider);
        if (cloudReady) {
          _showMessage(
            'Sync obrigatório em produção. Não é possível desativar após a configuração inicial.',
          );
          return;
        }
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
        if (ok != true) return;
        ref.invalidate(authStateProvider);
        if (!ref.read(isAuthenticatedProvider)) return;
      }

      await AppLog.write('Sync: usuário habilitou Firestore');
      await setSyncEnabled(ref, true);
      if (!mounted) return;
      _showMessage('Sincronização Firestore ativa.');
    } catch (e, st) {
      await AppLog.write('Sync: erro ao habilitar', error: e, stack: st);
      if (!mounted) return;
      _showMessage('Erro ao sincronizar: $e');
    }
  }

  Future<void> _loginToCloud() async {
    try {
      if (!isFirebaseAvailable) {
        _showMessage(firebaseUnavailableMessage);
        return;
      }
      await AppLog.write('Sync: abrindo login na nuvem');
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const LoginScreen()),
      );
      if (!mounted) return;
      if (ok == true && ref.read(isAuthenticatedProvider)) {
        ref.invalidate(firestoreSyncServiceProvider);
        ref.invalidate(syncQueueProcessorProvider);
        await kickSyncQueue(ref);
        if (!mounted) return;
        _showMessage(
          'Login na nuvem concluído. Sincronização automática retomada.',
        );
      }
    } catch (e, st) {
      await AppLog.write('Sync: erro no login na nuvem', error: e, stack: st);
      if (!mounted) return;
      _showMessage('Erro no login: $e');
    }
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
    await kickSyncQueue(ref);
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
    await kickSyncQueue(ref);
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProvisioningWizard()));
    if (mounted) setState(() {});
  }

  Future<void> _resetBancadaWifi() async {
    final deviceId = _bancadaDeviceId;
    if (deviceId == null) {
      _showMessage('Selecione uma bancada');
      return;
    }

    final mqttService = ref.read(mqttServiceProvider);
    if (mqttService.currentState != AppMqttConnectionState.connected) {
      _showMessage(
        'MQTT desconectado — conecte ao broker antes de resetar a bancada',
      );
      return;
    }

    final device = ref.read(devicesProvider)[deviceId];
    if (device?.estado == DeviceFsmState.testing) {
      _showMessage(
        'Bancada em teste — aguarde o fim do teste para resetar o Wi-Fi',
      );
      return;
    }
    if (device?.estado == DeviceFsmState.otaUpdating) {
      _showMessage('Bancada em atualização de firmware — aguarde a conclusão');
      return;
    }

    final confirmController = TextEditingController();
    var clearMqtt = false;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reset Wi-Fi da bancada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Isso apaga as credenciais Wi-Fi na NVS da bancada. '
                'Ela reiniciará em modo provisionamento (AP SireneValidator). '
                'Lote e fila offline não são apagados. Digite RESET para confirmar.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(labelText: 'Confirmação'),
                autofocus: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Apagar broker MQTT na bancada também'),
                subtitle: const Text(
                  'Remove host/porta MQTT gravados na NVS do ESP32',
                ),
                value: clearMqtt,
                onChanged: (v) => setDialogState(() => clearMqtt = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (confirmController.text.trim() != 'RESET') {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Digite RESET para confirmar'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Resetar Wi-Fi'),
            ),
          ],
        ),
      ),
    );

    confirmController.dispose();
    if (proceed != true || !mounted) return;

    final rejection = await ref
        .read(devicesProvider.notifier)
        .sendResetWifi(deviceId, clearMqtt: clearMqtt);
    if (!mounted) return;

    if (rejection != null) {
      _showMessage('Reset rejeitado: $rejection');
      return;
    }

    await ref.read(appConfigProvider).setWifiProvisioned(false);
    ref.invalidate(wifiProvisionedProvider);

    final openProvisioning = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset iniciado'),
        content: Text(
          'A bancada está reiniciando. Conecte o PC ao AP ${ProvisioningConstants.apSsid} '
          '(senha: ${ProvisioningConstants.apPassword}) e use o assistente de provisionamento '
          'para configurar o Wi-Fi novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Depois'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abrir assistente'),
          ),
        ],
      ),
    );

    if (openProvisioning == true && mounted) {
      await _openProvisioning();
    }
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
                onChanged: (v) =>
                    setDialogState(() => logoutFirebase = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (confirmController.text.trim() != 'ZERAR') {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Digite ZERAR para confirmar'),
                    ),
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
      await ref
          .read(factoryResetServiceProvider)
          .execute(logoutFirebase: logoutFirebase);
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Operador desconectado')));
    }
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider)?.signOut();
    await setSyncEnabled(ref, false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sessão encerrada')));
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
    if (!ref.read(isAuthenticatedProvider)) {
      _showMessage('Faça login na nuvem antes de reprocessar a fila.');
      return;
    }
    try {
      await AppLog.write(
        'Sync: reprocessar falhas (item=${itemId ?? 'todos'})',
      );
      await retryFailedSyncItems(ref, itemId: itemId);
      if (!mounted) return;
      _showMessage(
        itemId != null
            ? 'Item reenfileirado para sync'
            : 'Falhas reenfileiradas para sync',
      );
    } catch (e, st) {
      await AppLog.write('Sync: erro ao reprocessar', error: e, stack: st);
      if (!mounted) return;
      _showMessage('Erro ao reprocessar fila: $e');
    }
  }

  Future<void> _toggleDemoMode(bool enabled) async {
    try {
      if (enabled) {
        await enableDemoMode(ref);
        if (!mounted) return;
        setState(() => _bancadaDeviceId = kDemoDeviceId);
        _showMessage(
          'Modo demonstração ativo. Use Lote → iniciar OP → Autoplay no painel ao vivo.',
        );
      } else {
        await disableDemoMode(ref);
        if (!mounted) return;
        _showMessage('Modo demonstração desativado.');
      }
      ref.invalidate(appConfigProvider);
    } catch (e) {
      _showMessage('Erro ao alterar modo demo: $e');
    }
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
    final mqttAsync = ref.watch(mqttConnectionStateProvider);
    final mqttService = ref.watch(mqttServiceProvider);
    final mqttConnected =
        resolveMqttConnectionDisplayState(
          mqttAsync,
          mqttService.currentState,
        ) ==
        AppMqttConnectionState.connected;
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
    final operatorName = activeOpAsync.valueOrNull?.nome ?? '—';
    final bancadaLabel = _bancadaDeviceId != null
        ? formatBancadaLabelFromMap(_bancadaDeviceId!, bancadas)
        : 'Sem bancada';

    return Scaffold(
      appBar: screenAppBar(context, title: 'Configurações'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsStatusHeader(
            operatorName: operatorName,
            mqttConnected: mqttConnected,
            bancadaLabel: bancadaLabel,
            wifiProvisioned: wifiProvisioned,
            syncEnabled: syncEnabled,
            onlineBancadas: onlineCount,
            totalBancadas: devices.length,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSidebar = constraints.maxWidth >= 760;
                if (useSidebar) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsCategoryNav(
                        selected: _selectedCategory,
                        onSelected: (c) =>
                            setState(() => _selectedCategory = c),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _buildCategoryPanel(
                          syncStatus: syncStatus,
                          failedItems: failedItems,
                          authenticated: authenticated,
                          syncEnabled: syncEnabled,
                          devices: devices,
                          activeOpAsync: activeOpAsync,
                          wifiProvisioned: wifiProvisioned,
                          mqttConnected: mqttConnected,
                          bancadas: bancadas,
                          deviceList: deviceList,
                          onlineCount: onlineCount,
                          dateFmt: dateFmt,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsCategoryNav(
                      selected: _selectedCategory,
                      compact: true,
                      onSelected: (c) => setState(() => _selectedCategory = c),
                    ),
                    Expanded(
                      child: _buildCategoryPanel(
                        syncStatus: syncStatus,
                        failedItems: failedItems,
                        authenticated: authenticated,
                        syncEnabled: syncEnabled,
                        devices: devices,
                        activeOpAsync: activeOpAsync,
                        wifiProvisioned: wifiProvisioned,
                        mqttConnected: mqttConnected,
                        bancadas: bancadas,
                        deviceList: deviceList,
                        onlineCount: onlineCount,
                        dateFmt: dateFmt,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildSaveBar(),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return Material(
      elevation: 8,
      color: DipontoColors.surfaceVariant,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Alterações em ${_selectedCategory.title} exigem salvar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DipontoColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar configurações'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPanel({
    required AsyncValue<SyncStatus> syncStatus,
    required AsyncValue<List<SyncQueueData>> failedItems,
    required bool authenticated,
    required bool syncEnabled,
    required Map<String, DeviceInfo> devices,
    required AsyncValue<Operator?> activeOpAsync,
    required bool wifiProvisioned,
    required bool mqttConnected,
    required Map<String, int> bancadas,
    required List<DeviceInfo> deviceList,
    required int onlineCount,
    required DateFormat dateFmt,
  }) {
    final category = _selectedCategory;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: switch (category) {
            SettingsCategory.posto => _buildPostoSection(
              activeOpAsync: activeOpAsync,
              devices: devices,
              onlineCount: onlineCount,
            ),
            SettingsCategory.manutencao => _buildManutencaoSection(
              wifiProvisioned: wifiProvisioned,
              mqttConnected: mqttConnected,
              bancadas: bancadas,
              deviceList: deviceList,
            ),
            SettingsCategory.rede => _buildRedeSection(),
            SettingsCategory.marcacao => _buildMarcacaoSection(),
            SettingsCategory.nuvem => SettingsNuvemPanel(
              category: _selectedCategory,
              stationIdController: _stationId,
              syncStatus: syncStatus,
              failedItems: failedItems,
              authenticated: authenticated,
              syncEnabled: syncEnabled,
              dateFmt: dateFmt,
              onSyncToggle: _onSyncToggle,
              onLogin: _loginToCloud,
              onLogout: _logout,
              onSyncCatalog: _syncCatalog,
              onPullCatalog: _pullCatalog,
              onRetryFailed: _retryFailedSync,
            ),
            SettingsCategory.produtividade => _buildProdutividadeSection(),
          },
        ),
      ),
    );
  }

  Widget _buildPostoSection({
    required AsyncValue<Operator?> activeOpAsync,
    required Map<String, DeviceInfo> devices,
    required int onlineCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionIntro(
          title: _selectedCategory.title,
          subtitle: _selectedCategory.subtitle,
          icon: _selectedCategory.icon,
        ),
        ActionSectionCard(
          icon: Icons.badge_outlined,
          title: 'Operador ativo',
          subtitle: 'Sessão do turno neste posto',
          child: activeOpAsync.when(
            loading: () => const Text('Carregando...'),
            error: (_, __) => const Text('Erro ao carregar operador'),
            data: (op) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: DipontoColors.primary.withValues(
                      alpha: 0.2,
                    ),
                    child: Text(
                      (op?.nome.isNotEmpty == true ? op!.nome[0] : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: DipontoColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(op?.nome ?? '—'),
                  subtitle: op != null
                      ? Text(
                          op.isGestor ? 'Gestor do posto' : 'Operador do turno',
                        )
                      : null,
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
        ActionSectionCard(
          icon: Icons.devices_outlined,
          title: PortugueseLabels.navBancadas,
          subtitle: devices.isEmpty
              ? 'Nenhuma bancada detectada na rede'
              : '$onlineCount de ${devices.length} conectadas agora',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
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
              const Divider(),
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
              const Divider(),
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
      ],
    );
  }

  Widget _buildManutencaoSection({
    required bool wifiProvisioned,
    required bool mqttConnected,
    required Map<String, int> bancadas,
    required List<DeviceInfo> deviceList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionIntro(
          title: _selectedCategory.title,
          subtitle: _selectedCategory.subtitle,
          icon: _selectedCategory.icon,
        ),
        ActionSectionCard(
          icon: Icons.link,
          title: 'Bancada vinculada',
          subtitle: _bancadaDeviceId != null
              ? formatBancadaLabelFromMap(_bancadaDeviceId!, bancadas)
              : 'Nenhuma bancada selecionada para este posto',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (deviceList.isEmpty)
                const Text('Nenhuma bancada detectada na rede MQTT.')
              else
                DropdownButtonFormField<String>(
                  value: validDropdownValue(
                    _bancadaDeviceId,
                    deviceList.map((d) => d.deviceId),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Bancada vinculada',
                  ),
                  items: [
                    for (final d in deviceList)
                      DropdownMenuItem(
                        value: d.deviceId,
                        child: Text(
                          formatBancadaLabelFromMap(d.deviceId, bancadas),
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _bancadaDeviceId = v),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: deviceList.isEmpty ? null : _saveBancada,
                  child: const Text('Salvar vínculo'),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 520;
            final wifiCard = ActionSectionCard(
              icon: Icons.wifi,
              title: wifiProvisioned
                  ? 'Wi-Fi provisionado'
                  : 'Provisionar Wi-Fi',
              subtitle: 'Conectar bancadas à rede da fábrica',
              accentColor: wifiProvisioned
                  ? DipontoColors.success
                  : DipontoColors.primary,
              trailing: Icon(
                Icons.chevron_right,
                color: DipontoColors.onSurface.withValues(alpha: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    wifiProvisioned
                        ? 'As bancadas já foram configuradas neste posto.'
                        : 'Use o assistente para abrir o portal do ESP32.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openProvisioning,
                    icon: Icon(
                      wifiProvisioned
                          ? Icons.settings_ethernet
                          : Icons.wifi_find,
                    ),
                    label: Text(
                      wifiProvisioned
                          ? 'Reabrir assistente'
                          : 'Iniciar provisionamento',
                    ),
                  ),
                ],
              ),
            );
            final resetCard = ActionSectionCard(
              icon: Icons.wifi_find_outlined,
              title: 'Reset Wi-Fi na NVS',
              subtitle: 'Apaga credenciais gravadas na bancada',
              accentColor: Colors.orangeAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Envia RESET_WIFI via MQTT. A bancada reinicia em modo '
                    'SireneValidator. Lote e fila offline não são apagados.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent),
                    ),
                    onPressed: _bancadaDeviceId != null && mqttConnected
                        ? _resetBancadaWifi
                        : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Wi-Fi da bancada'),
                  ),
                  if (_bancadaDeviceId == null || !mqttConnected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _bancadaDeviceId == null
                            ? 'Selecione uma bancada acima.'
                            : 'MQTT desconectado — não é possível enviar o comando.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            );
            if (!twoCol) {
              return Column(children: [wifiCard, resetCard]);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: wifiCard),
                  const SizedBox(width: 16),
                  Expanded(child: resetCard),
                ],
              ),
            );
          },
        ),
        ActionSectionCard(
          icon: Icons.qr_code_scanner,
          title: 'Reconciliação de série',
          subtitle: 'Corrigir divergências entre app e bancada',
          accentColor: DipontoColors.primaryLight,
          child: const SerialReconciliationPanel(),
        ),
        ActionSectionCard(
          icon: Icons.science_outlined,
          title: 'Modo ensaio',
          subtitle: 'Ciclos ligado/desligado para teste de resistência',
          accentColor: Colors.amberAccent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Configurar ensaio'),
            subtitle: const Text(
              'Ex.: 1 min ligado, 1 min desligado, por 120 min',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EnsaioScreen()),
              );
            },
          ),
        ),
        ActionSectionCard(
          icon: Icons.smart_display_outlined,
          title: 'Modo demonstração',
          subtitle: 'Apresentar o software sem bancada ESP32 nem MQTT',
          accentColor: Colors.deepPurpleAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: ref.watch(demoModeProvider),
                onChanged: _toggleDemoMode,
                title: const Text('Ativar demonstração'),
                subtitle: const Text(
                  'Cria bancada virtual ($kDemoDeviceId), inicia lotes localmente '
                  'e permite simular testes com autoplay no painel ao vivo. '
                  'Não envia dados à nuvem.',
                ),
              ),
            ],
          ),
        ),
        DangerZone(
          title: 'Zona de perigo',
          description:
              'O reset geral apaga todos os dados locais deste posto (SQLite, catálogo, '
              'histórico). Não afeta a NVS da bancada — use o reset Wi-Fi acima para isso.',
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: DipontoColors.error,
              side: const BorderSide(color: DipontoColors.error),
            ),
            onPressed: _factoryReset,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Reset geral do posto'),
          ),
        ),
      ],
    );
  }

  Widget _buildRedeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionIntro(
          title: _selectedCategory.title,
          subtitle: _selectedCategory.subtitle,
          icon: _selectedCategory.icon,
        ),
        ActionSectionCard(
          icon: Icons.hub_outlined,
          title: 'Broker MQTT',
          subtitle: 'Conexão entre o app e as bancadas (nuvem Diponto)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResponsiveFieldRow(
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
              const SizedBox(height: 12),
              TextField(
                controller: _mqttSite,
                decoration: const InputDecoration(
                  labelText: 'Ambiente MQTT (site)',
                  helperText: 'Só assina tópicos deste site — padrão: producao',
                ),
              ),
              const SizedBox(height: 12),
              ResponsiveFieldRow(
                flexes: const [5, 5],
                children: [
                  TextField(
                    controller: _mqttWsPath,
                    decoration: const InputDecoration(
                      labelText: 'Basepath WebSocket',
                      helperText: 'Ex.: ws → wss://host:443/ws',
                    ),
                    enabled: _mqttUseWebSocket,
                  ),
                  TextField(
                    controller: _mqttUsername,
                    decoration: const InputDecoration(labelText: 'Usuário'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mqttPassword,
                obscureText: !_mqttPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    tooltip: _mqttPasswordVisible
                        ? 'Ocultar senha'
                        : 'Mostrar senha',
                    icon: Icon(
                      _mqttPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _mqttPasswordVisible = !_mqttPasswordVisible,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('WebSocket'),
                subtitle: const Text(
                  'Broker na nuvem usa WebSocket (porta 443)',
                ),
                value: _mqttUseWebSocket,
                onChanged: (value) => setState(() => _mqttUseWebSocket = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('TLS (WSS)'),
                subtitle: const Text(
                  'Conexão segura — recomendado na porta 443',
                ),
                value: _mqttUseTls,
                onChanged: _mqttUseWebSocket
                    ? (value) => setState(() => _mqttUseTls = value)
                    : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _save();
                    if (!mounted) return;
                    final state = ref.read(mqttServiceProvider).currentState;
                    final ok = state == AppMqttConnectionState.connected;
                    _showMessage(
                      ok
                          ? 'MQTT conectado (${ref.read(appConfigProvider).mqttUri})'
                          : 'Falha ao conectar — verifique host, porta, usuário e senha',
                    );
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Testar conexão'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarcacaoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionIntro(
          title: _selectedCategory.title,
          subtitle: _selectedCategory.subtitle,
          icon: _selectedCategory.icon,
        ),
        ActionSectionCard(
          icon: Icons.precision_manufacturing_outlined,
          title: 'Gravação laser DiatuCAD',
          subtitle:
              'Servidor TCP no app — F2 grava serial e nome do modelo',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  labelText: 'Comando TCP do serial (DataMatrix)',
                  helperText:
                      'Objeto DataMatrix no DiatuCAD — padrão: ${AppConfig.defaultLaserTcpCommand}',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _laserModelCommand,
                decoration: InputDecoration(
                  labelText: 'Comando TCP do modelo (texto)',
                  helperText:
                      'Objeto de texto no DiatuCAD — padrão: ${AppConfig.defaultLaserModelCommand}',
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
          ),
        ),
      ],
    );
  }

  Widget _buildProdutividadeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionIntro(
          title: _selectedCategory.title,
          subtitle: _selectedCategory.subtitle,
          icon: _selectedCategory.icon,
        ),
        ActionSectionCard(
          icon: Icons.trending_up,
          title: 'Metas do turno',
          subtitle: 'Rendimento esperado e início do expediente',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Meta de rendimento: ${_yieldTargetPct.toStringAsFixed(0)}%',
              ),
              Slider(
                value: _yieldTargetPct,
                min: 50,
                max: 99,
                divisions: 49,
                label: '${_yieldTargetPct.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _yieldTargetPct = v),
              ),
              DropdownButtonFormField<int>(
                value: _shiftStartHour,
                decoration: const InputDecoration(
                  labelText: 'Início do turno (hora)',
                ),
                items: List.generate(
                  24,
                  (h) => DropdownMenuItem(value: h, child: Text('$h:00')),
                ),
                onChanged: (v) {
                  if (v != null) setState(() => _shiftStartHour = v);
                },
              ),
            ],
          ),
        ),
        ActionSectionCard(
          icon: Icons.pause_circle_outline,
          title: 'Paradas de produção',
          subtitle: 'Registrar interrupções no turno',
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _registerDowntime,
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('Registrar parada'),
            ),
          ),
        ),
      ],
    );
  }
}
