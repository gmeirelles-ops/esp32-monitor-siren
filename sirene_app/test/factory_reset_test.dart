import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sirene_app/core/config/app_config.dart';
import 'package:sirene_app/core/providers/core_providers.dart';
import 'package:sirene_app/core/services/factory_reset_service.dart';
import 'package:sirene_app/features/operators/operators_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FactoryResetService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'selected_device_id': 'aa:bb:cc',
        'bancada_setup_complete': true,
        'wifi_provisioned': true,
        'mqtt_host': '10.0.0.1',
      });
      prefs = await SharedPreferences.getInstance();
    });

    test('clears prefs and session flags', () async {
      var dbClosed = false;
      var fileDeleted = false;

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          factoryResetServiceProvider.overrideWith((ref) {
            return FactoryResetService(
              ref: ref,
              prefs: ref.watch(sharedPreferencesProvider),
              closeDatabase: () async => dbClosed = true,
              deleteDatabaseFile: () async => fileDeleted = true,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(sessionOperatorIdProvider.notifier).state = 42;

      await container.read(factoryResetServiceProvider).execute();

      expect(dbClosed, isTrue);
      expect(fileDeleted, isTrue);
      expect(prefs.getKeys(), isEmpty);
      expect(container.read(sessionOperatorIdProvider), isNull);
      expect(container.read(bancadaSetupCompleteProvider), isFalse);
      expect(container.read(wifiProvisionedProvider), isFalse);
    });
  });

  group('AppConfig.migrateBancadaSetupIfNeeded', () {
    test('sets bancada_setup_complete when device id exists', () async {
      SharedPreferences.setMockInitialValues({'selected_device_id': 'dev1'});
      final prefs = await SharedPreferences.getInstance();
      await AppConfig.migrateBancadaSetupIfNeeded(prefs);
      expect(prefs.getBool('bancada_setup_complete'), isTrue);
    });

    test('does nothing without selected device', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await AppConfig.migrateBancadaSetupIfNeeded(prefs);
      expect(prefs.containsKey('bancada_setup_complete'), isFalse);
    });
  });
}
