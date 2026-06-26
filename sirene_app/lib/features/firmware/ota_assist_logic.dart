import 'dart:io';

import '../mqtt/models/mqtt_messages.dart';

const kOtaServedFileName = 'sirene-validator.bin';
const kMinFirmwareBinBytes = 100 * 1024;
const kDefaultOtaHttpPort = 8080;

/// Monta URL HTTP servida pelo app para OTA.
String buildOtaFirmwareUrl(String lanIp, int port, {String fileName = kOtaServedFileName}) {
  return 'http://$lanIp:$port/$fileName';
}

/// Escolhe IPv4 LAN na mesma faixa do broker MQTT, se possível.
String? pickLanIPv4(Iterable<String> candidates, {String? mqttBrokerHost}) {
  final usable = candidates
      .where((ip) => !ip.startsWith('127.') && !ip.startsWith('169.254.'))
      .toList();
  if (usable.isEmpty) return null;

  if (mqttBrokerHost != null && mqttBrokerHost.isNotEmpty && mqttBrokerHost != 'localhost') {
    final parts = mqttBrokerHost.split('.');
    if (parts.length == 4) {
      final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';
      for (final ip in usable) {
        if (ip.startsWith(prefix)) return ip;
      }
    }
  }
  return usable.first;
}

Future<String?> detectLanIPv4({String? mqttBrokerHost}) async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
  );
  final ips = <String>[];
  for (final iface in interfaces) {
    for (final addr in iface.addresses) {
      ips.add(addr.address);
    }
  }
  return pickLanIPv4(ips, mqttBrokerHost: mqttBrokerHost);
}

bool isFirmwareBinSizeValid(int byteLength) => byteLength >= kMinFirmwareBinBytes;

/// Retorna mensagem de erro ou null se OTA pode iniciar.
String? otaPrecheckError(DeviceInfo device) {
  if (!device.isOnline) {
    return 'Bancada offline — aguarde presença MQTT';
  }
  if (device.estado == DeviceFsmState.testing) {
    return 'Teste em andamento — aguarde concluir';
  }
  if (device.estado == DeviceFsmState.otaUpdating) {
    return 'OTA já em andamento nesta bancada';
  }
  return null;
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
