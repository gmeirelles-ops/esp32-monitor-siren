import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/mqtt/mqtt_service.dart';
import 'package:sqlite3/open.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  Future<ProviderContainer> createContainer(
    MqttService mqtt, {
    Map<String, DeviceInfo> devices = const {},
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        mqttServiceProvider.overrideWithValue(mqtt),
        devicesProvider.overrideWith((ref) => DevicesNotifier.forTesting(ref, devices)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('sendResetWifi publica RESET_WIFI sem clear_mqtt', () async {
    final mqtt = MqttService()
      ..testMode = true
      ..connectionStateForTest = AppMqttConnectionState.connected;
    final container = await createContainer(mqtt, devices: {
      'dev-abc': DeviceInfo(deviceId: 'dev-abc')..bancadaNum = 1,
    });
    final notifier = container.read(devicesProvider.notifier);

    final rejection = await notifier.sendResetWifi('dev-abc');

    expect(rejection, isNull);
    expect(mqtt.testPublishedCommands, hasLength(1));
    expect(mqtt.testPublishedCommands.single.bancadaNum, 1);
    expect(mqtt.testPublishedCommands.single.payload, {'cmd': 'RESET_WIFI'});
  });

  test('sendResetWifi publica RESET_WIFI com clear_mqtt', () async {
    final mqtt = MqttService()
      ..testMode = true
      ..connectionStateForTest = AppMqttConnectionState.connected;
    final container = await createContainer(mqtt, devices: {
      'dev-xyz': DeviceInfo(deviceId: 'dev-xyz')..bancadaNum = 2,
    });
    final notifier = container.read(devicesProvider.notifier);

    final rejection = await notifier.sendResetWifi('dev-xyz', clearMqtt: true);
    expect(mqtt.testPublishedCommands.single.payload, {
      'cmd': 'RESET_WIFI',
      'clear_mqtt': true,
    });
  });

  test('sendResetWifi retorna mqtt_desconectado quando broker offline', () async {
    final mqtt = MqttService()..testMode = true;
    final container = await createContainer(mqtt);
    final notifier = container.read(devicesProvider.notifier);

    final rejection = await notifier.sendResetWifi('dev-abc');

    expect(rejection, 'mqtt_desconectado');
    expect(mqtt.testPublishedCommands, isEmpty);
  });
}
