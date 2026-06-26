import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/firmware/usb_flash_logic.dart';

void main() {
  group('buildAppOnlyFlashArgs', () {
    test('inclui offset 0x20000', () {
      final args = buildAppOnlyFlashArgs(comPort: 'COM3', appBinPath: r'C:\fw\sirene-validator.bin');
      expect(args, contains('COM3'));
      expect(args, contains(FirmwareFlashOffsets.appImage));
      expect(args.last, r'C:\fw\sirene-validator.bin');
    });
  });

  group('buildFullFlashArgs', () {
    test('inclui quatro imagens', () {
      final args = buildFullFlashArgs(
        comPort: 'COM5',
        bootloaderPath: 'boot.bin',
        partitionTablePath: 'part.bin',
        otaDataPath: 'ota.bin',
        appBinPath: 'app.bin',
      );
      expect(args.where((a) => a.startsWith('0x')).length, 4);
      expect(args, contains('boot.bin'));
      expect(args, contains('app.bin'));
    });
  });

  group('esptoolLogIndicatesSuccess', () {
    test('detecta hash verified', () {
      expect(esptoolLogIndicatesSuccess('Hash of data verified'), isTrue);
    });
  });

  group('esptoolExitSuccess', () {
    test('aceita exit 0', () {
      expect(esptoolExitSuccess(0, ''), isTrue);
    });
  });
}
