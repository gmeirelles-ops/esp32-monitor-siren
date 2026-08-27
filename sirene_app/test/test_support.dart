import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/core/providers/core_providers.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/mqtt/mqtt_service.dart';

/// SharedPreferences de teste (gravação laser).
Future<SharedPreferences> createTestPrefs({
  Map<String, Object> extra = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    ...extra,
  });
  return SharedPreferences.getInstance();
}

/// Overrides comuns: DB em memória, MQTT em testMode conectado, broker “conectado”.
List<Override> devicesTestOverrides({
  required AppDatabase db,
  required SharedPreferences prefs,
  Map<String, DeviceInfo>? devices,
  AppMqttConnectionState mqttState = AppMqttConnectionState.connected,
}) {
  final mqtt = MqttService()
    ..testMode = true
    ..connectionStateForTest = mqttState;
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    mqttServiceProvider.overrideWithValue(mqtt),
    devicesProvider.overrideWith(
      (ref) => DevicesNotifier.forTesting(
        ref,
        Map<String, DeviceInfo>.from(devices ?? {}),
      ),
    ),
    mqttConnectionStateProvider.overrideWith(
      (ref) => Stream.value(mqttState),
    ),
  ];
}
