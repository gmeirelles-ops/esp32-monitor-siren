import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/products/device_calibration.dart';

void main() {
  group('DeviceCalibration.canCalibrate', () {
    test('permite IDLE e BATCH_READY online', () {
      expect(
        DeviceCalibration.canCalibrate(deviceOnline: true, estado: 'IDLE'),
        isTrue,
      );
      expect(
        DeviceCalibration.canCalibrate(deviceOnline: true, estado: 'BATCH_READY'),
        isTrue,
      );
      expect(
        DeviceCalibration.canCalibrate(deviceOnline: true, estado: 'HARDWARE_FAULT'),
        isTrue,
      );
    });

    test('bloqueia offline e estados críticos', () {
      expect(
        DeviceCalibration.canCalibrate(deviceOnline: false, estado: 'IDLE'),
        isFalse,
      );
      for (final estado in ['TESTING', 'OTA_UPDATING', 'PROVISIONING']) {
        expect(
          DeviceCalibration.canCalibrate(deviceOnline: true, estado: estado),
          isFalse,
        );
      }
    });
  });
}
