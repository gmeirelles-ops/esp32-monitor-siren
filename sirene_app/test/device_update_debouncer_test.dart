import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/cloud/sync/device_update_debouncer.dart';

void main() {
  group('DeviceUpdateDebouncer', () {
    test('permite primeiro envio imediato', () {
      final debouncer = DeviceUpdateDebouncer(
        interval: const Duration(seconds: 60),
      );
      expect(debouncer.shouldSendNow('dev1'), isTrue);
    });

    test('bloqueia envio dentro do intervalo', () {
      final debouncer = DeviceUpdateDebouncer(
        interval: const Duration(seconds: 60),
      );
      debouncer.recordSent('dev1');
      expect(debouncer.shouldSendNow('dev1'), isFalse);
    });

    test('force ignora debounce', () {
      final debouncer = DeviceUpdateDebouncer(
        interval: const Duration(seconds: 60),
      );
      debouncer.recordSent('dev1');
      expect(debouncer.shouldSendNow('dev1', force: true), isTrue);
    });
  });
}
