/// Offsets do layout ESP32 sirene-validator (4 MB flash).
class FirmwareFlashOffsets {
  static const appImage = '0x20000';
  static const bootloader = '0x1000';
  static const partitionTable = '0x8000';
  static const otaData = '0xf000';
}

List<String> buildAppOnlyFlashArgs({
  required String comPort,
  required String appBinPath,
}) {
  return [
    '--chip',
    'esp32',
    '--port',
    comPort,
    '--baud',
    '460800',
    '--before',
    'default_reset',
    '--after',
    'hard_reset',
    'write_flash',
    '--flash_mode',
    'dio',
    '--flash_freq',
    '40m',
    '--flash_size',
    '4MB',
    FirmwareFlashOffsets.appImage,
    appBinPath,
  ];
}

List<String> buildFullFlashArgs({
  required String comPort,
  required String bootloaderPath,
  required String partitionTablePath,
  required String otaDataPath,
  required String appBinPath,
}) {
  return [
    '--chip',
    'esp32',
    '--port',
    comPort,
    '--baud',
    '460800',
    '--before',
    'default_reset',
    '--after',
    'hard_reset',
    'write_flash',
    '--flash_mode',
    'dio',
    '--flash_freq',
    '40m',
    '--flash_size',
    '4MB',
    FirmwareFlashOffsets.bootloader,
    bootloaderPath,
    FirmwareFlashOffsets.partitionTable,
    partitionTablePath,
    FirmwareFlashOffsets.otaData,
    otaDataPath,
    FirmwareFlashOffsets.appImage,
    appBinPath,
  ];
}

String normalizeComPort(String port) => port.trim();

bool esptoolExitSuccess(int exitCode, String combinedLog) {
  if (exitCode == 0) return true;
  return esptoolLogIndicatesSuccess(combinedLog);
}

bool esptoolLogIndicatesSuccess(String log) {
  final lower = log.toLowerCase();
  return lower.contains('hash of data verified') || lower.contains('hard resetting via rts');
}

bool esptoolLogIndicatesFailure(String log) {
  final lower = log.toLowerCase();
  return lower.contains('fatal error') ||
      lower.contains('a fatal error occurred') ||
      lower.contains('failed to connect');
}
