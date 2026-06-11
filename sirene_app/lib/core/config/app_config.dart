import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  AppConfig(this._prefs);

  final SharedPreferences _prefs;

  static const defaultMqttHost = '192.168.51.87';
  static const defaultMqttPort = 1883;
  static const defaultPrinterHost = '192.168.1.50';
  static const defaultPrinterPort = 9100;
  static const staleDeviceTimeout = Duration(seconds: 90);
  static const defaultStationId = 'posto-01';

  String get mqttHost => _prefs.getString('mqtt_host') ?? defaultMqttHost;
  int get mqttPort => _prefs.getInt('mqtt_port') ?? defaultMqttPort;
  String get printerHost => _prefs.getString('printer_host') ?? defaultPrinterHost;
  int get printerPort => _prefs.getInt('printer_port') ?? defaultPrinterPort;
  String? get selectedDeviceId => _prefs.getString('selected_device_id');
  String get stationId => _prefs.getString('station_id') ?? defaultStationId;
  bool get syncEnabled => _prefs.getBool('sync_enabled') ?? false;

  String get mqttUri => 'mqtt://$mqttHost:$mqttPort';

  Future<void> setMqttHost(String value) => _prefs.setString('mqtt_host', value);
  Future<void> setMqttPort(int value) => _prefs.setInt('mqtt_port', value);
  Future<void> setPrinterHost(String value) => _prefs.setString('printer_host', value);
  Future<void> setPrinterPort(int value) => _prefs.setInt('printer_port', value);
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
}
