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

class AppConfig {
  AppConfig(this._prefs);

  final SharedPreferences _prefs;

  static const defaultMqttHost = '192.168.51.87';
  static const defaultMqttPort = 1883;
  static const defaultPrinterHost = '192.168.1.50';
  static const defaultPrinterPort = 9100;
  static const defaultPrinterMode = PrinterMode.usb;
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

  String get printerWindowsName => _prefs.getString('printer_windows_name') ?? '';
  String? get selectedDeviceId => _prefs.getString('selected_device_id');
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
  Future<void> setPrinterWindowsName(String value) =>
      _prefs.setString('printer_windows_name', value.trim());
  Future<void> setSelectedDeviceId(String? value) async {
    if (value == null) {
      await _prefs.remove('selected_device_id');
    } else {
      await _prefs.setString('selected_device_id', value);
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
