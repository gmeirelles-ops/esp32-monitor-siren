import 'dart:io';

import '../mqtt/models/mqtt_messages.dart';

const kOtaServedFileName = 'sirene-validator.bin';
const kMinFirmwareBinBytes = 100 * 1024;
const kDefaultOtaHttpPort = 8080;

/// Monta URL HTTP servida pelo app para OTA.
String buildOtaFirmwareUrl(String lanIp, int port, {String fileName = kOtaServedFileName}) {
  return 'http://$lanIp:$port/$fileName';
}

/// Adaptadores virtuais (WSL, Hyper-V, Docker…) — IP não alcançável pelo ESP32 na LAN.
bool isVirtualNetworkInterface(String name) {
  final lower = name.toLowerCase();
  return lower.contains('wsl') ||
      lower.contains('hyper-v') ||
      lower.contains('vethernet') ||
      lower.contains('virtualbox') ||
      lower.contains('vmware') ||
      lower.contains('docker') ||
      lower.contains('npcap') ||
      lower.contains('loopback');
}

bool isUsableOtaLanIp(String ip) {
  if (ip.startsWith('127.') || ip.startsWith('169.254.')) return false;
  // Gateway WSL/Docker no host Windows — ESP32 na Wi-Fi não alcança.
  if (ip == '172.20.0.1' || ip == '172.17.0.1') return false;
  return true;
}

int _otaIpSortPriority(String ip) {
  if (ip.startsWith('192.168.')) return 0;
  if (ip.startsWith('10.')) return 1;
  final parts = ip.split('.');
  if (parts.length == 4) {
    final second = int.tryParse(parts[1]);
    if (parts[0] == '172' && second != null && second >= 16 && second <= 31) {
      return 2;
    }
  }
  return 3;
}

/// Escolhe IPv4 LAN na mesma faixa do broker MQTT, se possível.
String? pickLanIPv4(Iterable<String> candidates, {String? mqttBrokerHost}) {
  final usable = candidates.where(isUsableOtaLanIp).toList();
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

  usable.sort((a, b) => _otaIpSortPriority(a).compareTo(_otaIpSortPriority(b)));
  return usable.first;
}

Future<String?> detectLanIPv4({String? mqttBrokerHost}) async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
  );
  final ips = <String>[];
  for (final iface in interfaces) {
    if (isVirtualNetworkInterface(iface.name)) continue;
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
