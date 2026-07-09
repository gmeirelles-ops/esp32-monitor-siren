/// Offsets do layout ESP32 sirene-validator (4 MB flash, partitions.csv).
class FirmwareFlashOffsets {
  static const appImage = '0x20000';
  static const ota1Image = '0x1a0000';
  static const bootloader = '0x1000';
  static const partitionTable = '0x8000';
  static const otaData = '0xf000';
}

List<String> _commonEsptoolWriteArgs(String comPort) => [
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
      '--no-stub',
      'write_flash',
      '--flash_mode',
      'dio',
      '--flash_freq',
      '40m',
      '--flash_size',
      '4MB',
    ];

/// Grava o app nas duas particoes OTA (evita boot no slot antigo).
List<String> buildOtaDualFlashArgs({
  required String comPort,
  required String appBinPath,
  String? otaDataPath,
}) {
  final args = [
    ..._commonEsptoolWriteArgs(comPort),
    FirmwareFlashOffsets.appImage,
    appBinPath,
    FirmwareFlashOffsets.ota1Image,
    appBinPath,
  ];
  if (otaDataPath != null && otaDataPath.isNotEmpty) {
    args.addAll([FirmwareFlashOffsets.otaData, otaDataPath]);
  }
  return args;
}

@Deprecated('Use buildOtaDualFlashArgs')
List<String> buildAppOnlyFlashArgs({
  required String comPort,
  required String appBinPath,
}) =>
    buildOtaDualFlashArgs(comPort: comPort, appBinPath: appBinPath);

List<String> buildFullFlashArgs({
  required String comPort,
  required String bootloaderPath,
  required String partitionTablePath,
  required String otaDataPath,
  required String appBinPath,
}) {
  return [
    ..._commonEsptoolWriteArgs(comPort),
    FirmwareFlashOffsets.bootloader,
    bootloaderPath,
    FirmwareFlashOffsets.partitionTable,
    partitionTablePath,
    FirmwareFlashOffsets.otaData,
    otaDataPath,
    FirmwareFlashOffsets.appImage,
    appBinPath,
    FirmwareFlashOffsets.ota1Image,
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
