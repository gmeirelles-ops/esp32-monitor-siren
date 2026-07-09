import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/firmware/usb_flash_logic.dart';

void main() {
  group('buildOtaDualFlashArgs', () {
    test('grava ota_0 e ota_1 com mesmo binario', () {
      final args = buildOtaDualFlashArgs(
        comPort: 'COM3',
        appBinPath: r'C:\fw\sirene-validator.bin',
      );
      expect(args, contains('COM3'));
      expect(args, contains('--no-stub'));
      expect(args, contains(FirmwareFlashOffsets.appImage));
      expect(args, contains(FirmwareFlashOffsets.ota1Image));
      expect(args.where((a) => a == r'C:\fw\sirene-validator.bin').length, 2);
    });

    test('inclui otadata quando informado', () {
      final args = buildOtaDualFlashArgs(
        comPort: 'COM3',
        appBinPath: r'C:\fw\sirene-validator.bin',
        otaDataPath: r'C:\fw\ota_data_initial.bin',
      );
      expect(args, contains(FirmwareFlashOffsets.otaData));
      expect(args, contains(r'C:\fw\ota_data_initial.bin'));
    });
  });

  group('buildAppOnlyFlashArgs', () {
    test('alias grava ambos slots OTA', () {
      final args = buildAppOnlyFlashArgs(comPort: 'COM3', appBinPath: r'C:\fw\sirene-validator.bin');
      expect(args, contains(FirmwareFlashOffsets.ota1Image));
    });
  });

  group('buildFullFlashArgs', () {
    test('inclui bootloader, partition, otadata e app em ambos slots OTA', () {
      final args = buildFullFlashArgs(
        comPort: 'COM5',
        bootloaderPath: 'boot.bin',
        partitionTablePath: 'part.bin',
        otaDataPath: 'ota.bin',
        appBinPath: 'app.bin',
      );
      expect(args.where((a) => a.startsWith('0x')).length, 5);
      expect(args.where((a) => a == 'app.bin').length, 2);
      expect(args, contains('boot.bin'));
      expect(args, contains(FirmwareFlashOffsets.ota1Image));
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
