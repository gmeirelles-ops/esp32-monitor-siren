import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/global_app_bar_actions.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import 'firmware_providers.dart';
import 'ota_assist_logic.dart';
import 'usb_flash_service.dart';

enum FirmwareUpdatePhase { idle, preparing, active, success, failed }

class FirmwareUpdateScreen extends ConsumerStatefulWidget {
  const FirmwareUpdateScreen({super.key, this.initialDeviceId});

  final String? initialDeviceId;

  @override
  ConsumerState<FirmwareUpdateScreen> createState() => _FirmwareUpdateScreenState();
}

class _FirmwareUpdateScreenState extends ConsumerState<FirmwareUpdateScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  FirmwareUpdatePhase _phase = FirmwareUpdatePhase.idle;
  String? _otaBinPath;
  String? _usbBinPath;
  String? _buildDirPath;
  String? _selectedDeviceId;
  String? _selectedComPort;
  UsbFlashMode _usbMode = UsbFlashMode.appOnly;
  int _otaPort = kDefaultOtaHttpPort;
  String? _statusMessage;
  String? _otaUrl;
  final List<String> _usbLog = [];
  StreamSubscription<OtaStatusMessage>? _otaSub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _selectedDeviceId = widget.initialDeviceId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedDeviceId == null) {
        setState(() => _selectedDeviceId = ref.read(appConfigProvider).selectedDeviceId);
      }
    });
  }

  @override
  void dispose() {
    _otaSub?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickOtaBin() async {
    const typeGroup = XTypeGroup(label: 'Firmware', extensions: ['bin']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    setState(() => _otaBinPath = file.path);
  }

  Future<void> _pickUsbBin() async {
    const typeGroup = XTypeGroup(label: 'Firmware', extensions: ['bin']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    setState(() => _usbBinPath = file.path);
  }

  Future<void> _pickBuildDir() async {
    final dir = await getDirectoryPath(confirmButtonText: 'Selecionar pasta build');
    if (dir == null) return;
    setState(() => _buildDirPath = dir);
  }

  Future<void> _startOta() async {
    final deviceId = _selectedDeviceId;
    final binPath = _otaBinPath;
    if (deviceId == null || binPath == null) {
      _setFailed('Selecione bancada e arquivo .bin');
      return;
    }

    final device = ref.read(devicesProvider)[deviceId];
    if (device == null) {
      _setFailed('Bancada não encontrada');
      return;
    }

    final precheck = otaPrecheckError(device);
    if (precheck != null) {
      _setFailed(precheck);
      return;
    }

    final config = ref.read(appConfigProvider);
    final beforeVersion = device.firmwareVersion;
    final otaService = ref.read(otaAssistServiceProvider);

    setState(() {
      _phase = FirmwareUpdatePhase.preparing;
      _statusMessage = 'Iniciando servidor HTTP...';
      _otaUrl = null;
    });

    try {
      final url = await otaService.startServing(
        sourceBinPath: binPath,
        port: _otaPort,
        mqttBrokerHost: config.mqttHost,
      );

      setState(() {
        _otaUrl = url;
        _phase = FirmwareUpdatePhase.active;
        _statusMessage = 'Enviando OTA para $deviceId...';
      });

      final completer = Completer<void>();
      _otaSub?.cancel();
      _otaSub = ref.read(mqttServiceProvider).otaEvents.listen((ota) {
        if (ota.evento == 'sucesso') {
          completer.complete();
        } else if (ota.evento == 'falha') {
          completer.completeError(StateError(ota.detalhe ?? 'falha OTA'));
        }
        if (mounted) {
          setState(() => _statusMessage = 'OTA ${ota.evento}: ${ota.detalhe ?? ''}');
        }
      });

      await ref.read(devicesProvider.notifier).sendOtaUpdate(deviceId, url);

      await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw TimeoutException('Timeout aguardando OTA'),
      );

      await _waitFirmwareVersionChange(deviceId, beforeVersion);

      if (!mounted) return;
      setState(() {
        _phase = FirmwareUpdatePhase.success;
        _statusMessage = 'Firmware atualizado com sucesso';
      });
    } catch (e) {
      _setFailed('$e');
    } finally {
      await otaService.stop();
      await _otaSub?.cancel();
      _otaSub = null;
    }
  }

  Future<void> _waitFirmwareVersionChange(String deviceId, String before) async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final version = ref.read(devicesProvider)[deviceId]?.firmwareVersion ?? '';
      if (version.isNotEmpty && version != before) return;
    }
  }

  Future<void> _startUsbFlash() async {
    if (!Platform.isWindows) {
      _setFailed('Gravação USB disponível apenas no Windows');
      return;
    }

    final port = _selectedComPort;
    if (port == null || port.isEmpty) {
      _setFailed('Selecione a porta COM');
      return;
    }

    final binPath = _usbMode == UsbFlashMode.appOnly ? _usbBinPath : null;
    if (_usbMode == UsbFlashMode.appOnly && (binPath == null || binPath.isEmpty)) {
      _setFailed('Selecione o arquivo sirene-validator.bin');
      return;
    }
    if (_usbMode == UsbFlashMode.full && (_buildDirPath == null || _buildDirPath!.isEmpty)) {
      _setFailed('Selecione a pasta build/');
      return;
    }

    final usb = ref.read(usbFlashServiceProvider);
    setState(() {
      _phase = FirmwareUpdatePhase.active;
      _statusMessage = 'Gravando via USB...';
      _usbLog.clear();
    });

    try {
      await usb.flash(
        mode: _usbMode,
        comPort: port,
        appBinPath: binPath ?? '',
        buildDirectory: _buildDirPath,
        onLog: (line) {
          if (mounted) {
            setState(() {
              _usbLog.add(line);
              if (_usbLog.length > 200) _usbLog.removeAt(0);
            });
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _phase = FirmwareUpdatePhase.success;
        _statusMessage = 'Gravação USB concluída';
      });
    } catch (e) {
      _setFailed('$e');
    }
  }

  void _setFailed(String message) {
    if (!mounted) return;
    setState(() {
      _phase = FirmwareUpdatePhase.failed;
      _statusMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final deviceList = devices.values.toList()
      ..sort((a, b) => a.deviceId.compareTo(b.deviceId));
    final ports = ref.watch(usbFlashServiceProvider).listSerialPorts();
    final busy = _phase == FirmwareUpdatePhase.preparing || _phase == FirmwareUpdatePhase.active;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizar firmware'),
        actions: globalAppBarActions(),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pela rede (OTA)', icon: Icon(Icons.wifi)),
            Tab(text: 'Por USB (cabo)', icon: Icon(Icons.usb)),
          ],
        ),
      ),
      body: DesktopFormLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_statusMessage != null) _StatusBanner(phase: _phase, message: _statusMessage!),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _OtaTab(
                    deviceList: deviceList,
                    selectedDeviceId: _selectedDeviceId,
                    binPath: _otaBinPath,
                    otaUrl: _otaUrl,
                    port: _otaPort,
                    busy: busy,
                    onDeviceChanged: (v) => setState(() => _selectedDeviceId = v),
                    onPickBin: _pickOtaBin,
                    onPortChanged: (v) => setState(() => _otaPort = v),
                    onStart: _startOta,
                  ),
                  _UsbTab(
                    ports: ports,
                    selectedPort: _selectedComPort,
                    mode: _usbMode,
                    binPath: _usbBinPath,
                    buildDir: _buildDirPath,
                    log: _usbLog,
                    busy: busy,
                    onPortChanged: (v) => setState(() => _selectedComPort = v),
                    onModeChanged: (m) => setState(() => _usbMode = m),
                    onPickBin: _pickUsbBin,
                    onPickBuildDir: _pickBuildDir,
                    onStart: _startUsbFlash,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.phase, required this.message});

  final FirmwareUpdatePhase phase;
  final String message;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (phase) {
      case FirmwareUpdatePhase.success:
        color = DipontoColors.success;
        icon = Icons.check_circle_outline;
      case FirmwareUpdatePhase.failed:
        color = DipontoColors.error;
        icon = Icons.error_outline;
      case FirmwareUpdatePhase.active:
      case FirmwareUpdatePhase.preparing:
        color = DipontoColors.primary;
        icon = Icons.sync;
      case FirmwareUpdatePhase.idle:
        color = DipontoColors.primaryLight;
        icon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withValues(alpha: 0.12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(message, style: TextStyle(color: color)),
      ),
    );
  }
}

class _OtaTab extends StatelessWidget {
  const _OtaTab({
    required this.deviceList,
    required this.selectedDeviceId,
    required this.binPath,
    required this.otaUrl,
    required this.port,
    required this.busy,
    required this.onDeviceChanged,
    required this.onPickBin,
    required this.onPortChanged,
    required this.onStart,
  });

  final List<DeviceInfo> deviceList;
  final String? selectedDeviceId;
  final String? binPath;
  final String? otaUrl;
  final int port;
  final bool busy;
  final ValueChanged<String?> onDeviceChanged;
  final VoidCallback onPickBin;
  final ValueChanged<int> onPortChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        FormSectionCard(
          title: 'OTA assistido',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'O app serve o .bin na rede e envia OTA_UPDATE automaticamente — '
                'sem Python nem MQTT Explorer.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedDeviceId,
                decoration: const InputDecoration(labelText: 'Bancada'),
                items: [
                  for (final d in deviceList)
                    DropdownMenuItem(
                      value: d.deviceId,
                      child: Text('${d.deviceId} (${d.isOnline ? "online" : "offline"})'),
                    ),
                ],
                onChanged: busy ? null : onDeviceChanged,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Arquivo firmware'),
                subtitle: Text(binPath ?? 'Nenhum arquivo selecionado'),
                trailing: OutlinedButton(onPressed: busy ? null : onPickBin, child: const Text('Escolher .bin')),
              ),
              TextFormField(
                initialValue: '$port',
                decoration: const InputDecoration(labelText: 'Porta HTTP local'),
                keyboardType: TextInputType.number,
                enabled: !busy,
                onChanged: (v) {
                  final p = int.tryParse(v);
                  if (p != null && p > 0 && p < 65536) onPortChanged(p);
                },
              ),
              if (otaUrl != null) ...[
                const SizedBox(height: 8),
                SelectableText('URL: $otaUrl', style: const TextStyle(fontSize: 12)),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: busy ? null : onStart,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt),
                label: const Text('Iniciar atualização OTA'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsbTab extends StatelessWidget {
  const _UsbTab({
    required this.ports,
    required this.selectedPort,
    required this.mode,
    required this.binPath,
    required this.buildDir,
    required this.log,
    required this.busy,
    required this.onPortChanged,
    required this.onModeChanged,
    required this.onPickBin,
    required this.onPickBuildDir,
    required this.onStart,
  });

  final List<String> ports;
  final String? selectedPort;
  final UsbFlashMode mode;
  final String? binPath;
  final String? buildDir;
  final List<String> log;
  final bool busy;
  final ValueChanged<String?> onPortChanged;
  final ValueChanged<UsbFlashMode> onModeChanged;
  final VoidCallback onPickBin;
  final VoidCallback onPickBuildDir;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        FormSectionCard(
          title: 'Gravação USB',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!Platform.isWindows)
                const Text('Disponível apenas no app Windows com cabo USB.'),
              DropdownButtonFormField<String>(
                value: ports.contains(selectedPort) ? selectedPort : null,
                decoration: const InputDecoration(labelText: 'Porta COM'),
                items: [
                  for (final p in ports) DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: busy ? null : onPortChanged,
              ),
              if (ports.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nenhuma porta COM — verifique cabo e driver CP210x/CH340'),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<UsbFlashMode>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Modo'),
                items: const [
                  DropdownMenuItem(
                    value: UsbFlashMode.appOnly,
                    child: Text('Atualizar app (0x20000)'),
                  ),
                  DropdownMenuItem(
                    value: UsbFlashMode.full,
                    child: Text('Flash completo (chip virgem / migração)'),
                  ),
                ],
                onChanged: busy ? null : (v) => v != null ? onModeChanged(v) : null,
              ),
              if (mode == UsbFlashMode.appOnly)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('sirene-validator.bin'),
                  subtitle: Text(binPath ?? 'Não selecionado'),
                  trailing: OutlinedButton(onPressed: busy ? null : onPickBin, child: const Text('Escolher')),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pasta build/'),
                  subtitle: Text(buildDir ?? 'Deve conter bootloader, partition, ota_data e app'),
                  trailing: OutlinedButton(
                    onPressed: busy ? null : onPickBuildDir,
                    child: const Text('Escolher pasta'),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: busy || !Platform.isWindows ? null : onStart,
                icon: const Icon(Icons.usb),
                label: const Text('Gravar via USB'),
              ),
            ],
          ),
        ),
        if (log.isNotEmpty)
          FormSectionCard(
            title: 'Log esptool',
            child: SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: SelectableText(log.join('\n'), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
            ),
          ),
      ],
    );
  }
}
