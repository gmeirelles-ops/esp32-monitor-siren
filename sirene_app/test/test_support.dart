import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/core/providers/core_providers.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';

/// SharedPreferences de teste. Por padrão usa laser (sem impressora USB).
/// Para testes do buffer de etiquetas, passe [useLaserMarking]: false.
Future<SharedPreferences> createTestPrefs({
  Map<String, Object> extra = const {},
  bool useLaserMarking = true,
}) async {
  SharedPreferences.setMockInitialValues({
    if (useLaserMarking) 'marking_mode': 'laser',
    if (!useLaserMarking) 'printer_mode': 'network',
    ...extra,
  });
  return SharedPreferences.getInstance();
}

/// Overrides comuns: DB em memória, sem MQTT real, broker “conectado”.
List<Override> devicesTestOverrides({
  required AppDatabase db,
  required SharedPreferences prefs,
  Map<String, DeviceInfo>? devices,
}) {
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    devicesProvider.overrideWith(
      (ref) => DevicesNotifier.forTesting(
        ref,
        Map<String, DeviceInfo>.from(devices ?? {}),
      ),
    ),
    mqttConnectionStateProvider.overrideWith(
      (ref) => Stream.value(AppMqttConnectionState.connected),
    ),
  ];
}
