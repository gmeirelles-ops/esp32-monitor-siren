import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

enum PrinterMode {
  usb,
  network;

  static PrinterMode fromStorage(String? value) {
    if (value == 'network') return PrinterMode.network;
    return PrinterMode.usb;
  }

  String get storageValue => this == PrinterMode.network ? 'network' : 'usb';
}

/// Marcação física do serial: etiqueta Zebra ou gravação laser DiatuCAD.
enum MarkingMode {
  labels,
  laser;

  static MarkingMode fromStorage(String? value) {
    if (value == 'laser') return MarkingMode.laser;
    return MarkingMode.labels;
  }

  String get storageValue => this == MarkingMode.laser ? 'laser' : 'labels';
}

class AppConfig {
  AppConfig(this._prefs);

  final SharedPreferences _prefs;

  static const defaultMqttHost = 'mqtt.diponto.com';
  static const defaultMqttPort = 443;
  static const defaultMqttSite = 'producao';
  static const defaultMqttWebSocketPath = 'ws';
  static const defaultMqttUseWebSocket = true;
  static const defaultMqttUseTls = true;
  static const defaultMqttUsername = 'devices';
  static const defaultMqttPassword = '';
  static const defaultPrinterHost = '192.168.1.50';
  static const defaultPrinterPort = 9100;
  static const defaultPrinterMode = PrinterMode.usb;
  static const defaultMarkingMode = MarkingMode.laser;
  static const defaultLaserTcpPort = 9101;
  static const defaultLaserTcpCommand = 'TCP: Give me string';
  static const defaultLaserModelCommand = 'TCP: model';
  static const laserTestSerial = '0000000000';
  static const staleDeviceTimeout = Duration(seconds: 90);
  static const defaultStationId = 'posto-01';
  static final stationIdPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
  static const defaultYieldTargetPct = 70.0;
  static const defaultShiftStartHour = 6;

  String get mqttHost => _prefs.getString('mqtt_host') ?? defaultMqttHost;
  int get mqttPort => _prefs.getInt('mqtt_port') ?? defaultMqttPort;
  String get mqttSite => _prefs.getString('mqtt_site') ?? defaultMqttSite;
  String get mqttWebSocketPath =>
      _prefs.getString('mqtt_ws_path') ?? defaultMqttWebSocketPath;
  bool get mqttUseWebSocket =>
      _prefs.getBool('mqtt_use_ws') ?? defaultMqttUseWebSocket;
  bool get mqttUseTls => _prefs.getBool('mqtt_use_tls') ?? defaultMqttUseTls;
  String get mqttUsername =>
      _prefs.getString('mqtt_username') ?? defaultMqttUsername;
  String get mqttPassword =>
      _prefs.getString('mqtt_password') ?? defaultMqttPassword;
  String get printerHost => _prefs.getString('printer_host') ?? defaultPrinterHost;
  int get printerPort => _prefs.getInt('printer_port') ?? defaultPrinterPort;
  PrinterMode get printerMode {
    final stored = _prefs.getString('printer_mode');
    if (stored != null) return PrinterMode.fromStorage(stored);
    return Platform.isWindows ? PrinterMode.usb : PrinterMode.network;
  }

  /// Marcação física: somente gravação laser DiatuCAD.
  MarkingMode get markingMode => MarkingMode.laser;

  int get laserTcpPort => _prefs.getInt('laser_tcp_port') ?? defaultLaserTcpPort;

  String get laserTcpCommand =>
      _prefs.getString('laser_tcp_command') ?? defaultLaserTcpCommand;

  String get laserModelCommand =>
      _prefs.getString('laser_model_command') ?? defaultLaserModelCommand;

  String get printerWindowsName => _prefs.getString('printer_windows_name') ?? '';
  String? get selectedDeviceId => _prefs.getString('selected_device_id');
  bool get bancadaSetupComplete => _prefs.getBool('bancada_setup_complete') ?? false;
  bool get wifiProvisioned => _prefs.getBool('wifi_provisioned') ?? false;
  String get stationId => _prefs.getString('station_id') ?? defaultStationId;
  bool get syncEnabled => _prefs.getBool('sync_enabled') ?? false;
  bool get cloudSetupComplete => _prefs.getBool('cloud_setup_complete') ?? false;
  bool get cloudSyncNeedsAttention => _prefs.getBool('cloud_sync_needs_attention') ?? false;
  DateTime? get lastCloudSyncAt {
    final raw = _prefs.getString('last_cloud_sync_at');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
  bool get demoModeEnabled => _prefs.getBool('demo_mode_enabled') ?? false;
  double get yieldTargetPct =>
      _prefs.getDouble('yield_target_pct') ?? defaultYieldTargetPct;
  int get shiftStartHour => _prefs.getInt('shift_start_hour') ?? defaultShiftStartHour;
  int? get activeOperatorId => _prefs.getInt('active_operator_id');

  /// Host/URL passado ao [MqttServerClient] (TCP ou `wss://host/path`).
  String get mqttClientServer {
    if (!mqttUseWebSocket) return mqttHost;
    final scheme = mqttUseTls ? 'wss' : 'ws';
    final path = mqttWebSocketPath.replaceAll(RegExp(r'^/+|/+$'), '');
    return '$scheme://$mqttHost/$path';
  }

  String get mqttUri {
    if (mqttUseWebSocket) {
      final scheme = mqttUseTls ? 'wss' : 'ws';
      final path = mqttWebSocketPath.replaceAll(RegExp(r'^/+|/+$'), '');
      return '$scheme://$mqttHost:$mqttPort/$path';
    }
    return 'mqtt://$mqttHost:$mqttPort';
  }

  Future<void> setMqttHost(String value) => _prefs.setString('mqtt_host', value);
  Future<void> setMqttPort(int value) => _prefs.setInt('mqtt_port', value);
  Future<void> setMqttSite(String value) =>
      _prefs.setString('mqtt_site', value.trim().isEmpty ? defaultMqttSite : value.trim());
  Future<void> setMqttWebSocketPath(String value) =>
      _prefs.setString('mqtt_ws_path', value.trim());
  Future<void> setMqttUseWebSocket(bool value) =>
      _prefs.setBool('mqtt_use_ws', value);
  Future<void> setMqttUseTls(bool value) => _prefs.setBool('mqtt_use_tls', value);
  Future<void> setMqttUsername(String value) =>
      _prefs.setString('mqtt_username', value.trim());
  Future<void> setMqttPassword(String value) =>
      _prefs.setString('mqtt_password', value);
  Future<void> setPrinterHost(String value) => _prefs.setString('printer_host', value);
  Future<void> setPrinterPort(int value) => _prefs.setInt('printer_port', value);
  Future<void> setPrinterMode(PrinterMode value) =>
      _prefs.setString('printer_mode', value.storageValue);
  Future<void> setMarkingMode(MarkingMode value) =>
      _prefs.setString('marking_mode', value.storageValue);
  Future<void> setLaserTcpPort(int value) => _prefs.setInt('laser_tcp_port', value);
  Future<void> setLaserTcpCommand(String value) =>
      _prefs.setString('laser_tcp_command', value.trim());
  Future<void> setLaserModelCommand(String value) =>
      _prefs.setString('laser_model_command', value.trim());
  Future<void> setPrinterWindowsName(String value) =>
      _prefs.setString('printer_windows_name', value.trim());
  Future<void> setSelectedDeviceId(String? value) async {
    if (value == null) {
      await _prefs.remove('selected_device_id');
    } else {
      await _prefs.setString('selected_device_id', value);
    }
  }

  Future<void> setBancadaSetupComplete(bool value) =>
      _prefs.setBool('bancada_setup_complete', value);

  Future<void> setWifiProvisioned(bool value) =>
      _prefs.setBool('wifi_provisioned', value);

  /// Postos que já tinham bancada salva antes desta versão.
  static Future<void> migrateBancadaSetupIfNeeded(SharedPreferences prefs) async {
    if (prefs.containsKey('bancada_setup_complete')) return;
    if (prefs.containsKey('selected_device_id')) {
      await prefs.setBool('bancada_setup_complete', true);
    }
  }

  static String normalizeStationId(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? defaultStationId : trimmed;
  }

  static bool isValidStationId(String value) {
    final normalized = normalizeStationId(value);
    return stationIdPattern.hasMatch(normalized);
  }

  Future<void> setStationId(String value) =>
      _prefs.setString('station_id', normalizeStationId(value));

  Future<void> setSyncEnabled(bool value) =>
      _prefs.setBool('sync_enabled', value);

  Future<void> setCloudSetupComplete(bool value) =>
      _prefs.setBool('cloud_setup_complete', value);

  Future<void> setCloudSyncNeedsAttention(bool value) =>
      _prefs.setBool('cloud_sync_needs_attention', value);

  Future<void> setLastCloudSyncAt(DateTime value) =>
      _prefs.setString('last_cloud_sync_at', value.toUtc().toIso8601String());

  Future<void> setDemoModeEnabled(bool value) =>
      _prefs.setBool('demo_mode_enabled', value);

  Future<void> setYieldTargetPct(double value) =>
      _prefs.setDouble('yield_target_pct', value);

  Future<void> setShiftStartHour(int value) =>
      _prefs.setInt('shift_start_hour', value);

  Future<void> setActiveOperatorId(int? value) async {
    if (value == null) {
      await _prefs.remove('active_operator_id');
    } else {
      await _prefs.setInt('active_operator_id', value);
    }
  }

  Future<void> clearActiveOperatorId() => setActiveOperatorId(null);
}
