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

  static const defaultMqttHost = '192.168.51.87';
  static const defaultMqttPort = 1883;
  static const defaultPrinterHost = '192.168.1.50';
  static const defaultPrinterPort = 9100;
  static const defaultPrinterMode = PrinterMode.usb;
  static const defaultMarkingMode = MarkingMode.labels;
  static const defaultLaserTcpPort = 9101;
  static const defaultLaserTcpCommand = 'TCP: Give me string';
  static const laserTestSerial = '0000000000';
  static const staleDeviceTimeout = Duration(seconds: 90);
  static const defaultStationId = 'posto-01';

  String get mqttHost => _prefs.getString('mqtt_host') ?? defaultMqttHost;
  int get mqttPort => _prefs.getInt('mqtt_port') ?? defaultMqttPort;
  String get printerHost => _prefs.getString('printer_host') ?? defaultPrinterHost;
  int get printerPort => _prefs.getInt('printer_port') ?? defaultPrinterPort;
  PrinterMode get printerMode {
    final stored = _prefs.getString('printer_mode');
    if (stored != null) return PrinterMode.fromStorage(stored);
    return Platform.isWindows ? PrinterMode.usb : PrinterMode.network;
  }

  MarkingMode get markingMode =>
      MarkingMode.fromStorage(_prefs.getString('marking_mode'));

  int get laserTcpPort => _prefs.getInt('laser_tcp_port') ?? defaultLaserTcpPort;

  String get laserTcpCommand =>
      _prefs.getString('laser_tcp_command') ?? defaultLaserTcpCommand;

  String get printerWindowsName => _prefs.getString('printer_windows_name') ?? '';
  String? get selectedDeviceId => _prefs.getString('selected_device_id');
  bool get bancadaSetupComplete => _prefs.getBool('bancada_setup_complete') ?? false;
  bool get wifiProvisioned => _prefs.getBool('wifi_provisioned') ?? false;
  String get stationId => _prefs.getString('station_id') ?? defaultStationId;
  bool get syncEnabled => _prefs.getBool('sync_enabled') ?? false;
  int? get activeOperatorId => _prefs.getInt('active_operator_id');

  String get mqttUri => 'mqtt://$mqttHost:$mqttPort';

  Future<void> setMqttHost(String value) => _prefs.setString('mqtt_host', value);
  Future<void> setMqttPort(int value) => _prefs.setInt('mqtt_port', value);
  Future<void> setPrinterHost(String value) => _prefs.setString('printer_host', value);
  Future<void> setPrinterPort(int value) => _prefs.setInt('printer_port', value);
  Future<void> setPrinterMode(PrinterMode value) =>
      _prefs.setString('printer_mode', value.storageValue);
  Future<void> setMarkingMode(MarkingMode value) =>
      _prefs.setString('marking_mode', value.storageValue);
  Future<void> setLaserTcpPort(int value) => _prefs.setInt('laser_tcp_port', value);
  Future<void> setLaserTcpCommand(String value) =>
      _prefs.setString('laser_tcp_command', value.trim());
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

  Future<void> setStationId(String value) =>
      _prefs.setString('station_id', value.trim());

  Future<void> setSyncEnabled(bool value) =>
      _prefs.setBool('sync_enabled', value);

  Future<void> setActiveOperatorId(int? value) async {
    if (value == null) {
      await _prefs.remove('active_operator_id');
    } else {
      await _prefs.setInt('active_operator_id', value);
    }
  }

  Future<void> clearActiveOperatorId() => setActiveOperatorId(null);
}
