import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/config/app_config.dart';
import 'package:sirene_app/core/utils/device_stale.dart';

void main() {
  group('isDeviceStale', () {
    test('marca offline após timeout sem mensagens', () {
      final now = DateTime(2026, 6, 10, 12, 0, 0);
      final lastSeen = now.subtract(AppConfig.staleDeviceTimeout + const Duration(seconds: 1));
      expect(isDeviceStale(lastSeen, now, AppConfig.staleDeviceTimeout), isTrue);
    });

    test('permanece online dentro do timeout', () {
      final now = DateTime(2026, 6, 10, 12, 0, 0);
      final lastSeen = now.subtract(const Duration(seconds: 30));
      expect(isDeviceStale(lastSeen, now, AppConfig.staleDeviceTimeout), isFalse);
    });

    test('lastSeen nulo não é stale', () {
      expect(isDeviceStale(null, DateTime.now(), AppConfig.staleDeviceTimeout), isFalse);
    });
  });
}
