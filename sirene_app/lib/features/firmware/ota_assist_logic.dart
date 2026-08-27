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

/// Checklist operacional exibido na UI antes/durante OTA assistido.
List<String> otaOperatorChecklist({required int httpPort}) => [
      'Bancada online e sem teste em andamento',
      'PC e ESP32 na mesma rede Wi‑Fi/LAN do broker MQTT',
      'Firewall Windows: permitir sirene_app na rede privada (porta $httpPort)',
      'Arquivo .bin válido (≥ ${kMinFirmwareBinBytes ~/ 1024} KB)',
    ];

/// Erro quando a porta HTTP não sobe (Dart nem Python).
String otaPortUnavailableMessage(int port, {Object? detail}) {
  final extra = detail == null ? '' : ' Detalhe: $detail';
  return 'Porta $port indisponível.$extra '
      'Feche outro servidor HTTP nessa porta ou escolha outra porta. '
      'No Firewall do Windows (rede privada), permita o sirene_app.exe.';
}

/// Servidor OK em localhost mas não no IP LAN (quase sempre firewall).
String otaLanUnreachableMessage(String lanIp, int port, {required String processHint}) {
  return 'Servidor OK em localhost, mas $lanIp:$port não responde na rede. '
      'No Firewall do Windows, libere a porta $port para $processHint '
      '(perfil rede privada). Confirme que o IP é o da Wi‑Fi/LAN do posto.';
}

/// Extrai host e porta de uma URL OTA já montada (para exibir na UI).
({String host, int port})? parseOtaFirmwareUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty || uri.port <= 0) return null;
  return (host: uri.host, port: uri.port);
}

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
