/// Tópicos MQTT alinhados ao firmware (`{site}/bancada-NN/{suffix}`).
abstract final class MqttTopics {
  /// Site/ambiente no broker compartilhado (ex.: producao, homologacao).
  static const defaultSite = 'producao';

  static final RegExp _bancadaSegment = RegExp(r'^bancada-(\d+)$');

  static String bancadaSegment(int bancadaNum) =>
      'bancada-${bancadaNum.toString().padLeft(2, '0')}';

  static String comando(String site, int bancadaNum) =>
      '$site/${bancadaSegment(bancadaNum)}/comando';

  static String status(String site, int bancadaNum) =>
      '$site/${bancadaSegment(bancadaNum)}/status';

  static String calibracao(String site, int bancadaNum) =>
      '$site/${bancadaSegment(bancadaNum)}/calibracao';

  static String ensaio(String site, int bancadaNum) =>
      '$site/${bancadaSegment(bancadaNum)}/ensaio';

  static String alerta(String site, int bancadaNum) =>
      '$site/${bancadaSegment(bancadaNum)}/alerta';

  static String presenca(String site, int bancadaNum) =>
      '$site/${bancadaSegment(bancadaNum)}/presenca';

  static String heartbeat(String site, int bancadaNum) =>
      '$site/${bancadaSegment(bancadaNum)}/heartbeat';

  /// Assinaturas restritas a um site — ignora outros ambientes no mesmo broker.
  static List<String> subscriptionsForSite(String site) => [
        '$site/+/presenca',
        '$site/+/heartbeat',
        '$site/+/status',
        '$site/+/calibracao',
        '$site/+/ensaio',
        '$site/+/alerta',
      ];

  /// Extrai o número da bancada de tópicos `producao/bancada-02/status`.
  static int? extractBancadaNum(String topic, {String? site}) {
    final parts = topic.split('/');
    if (parts.length < 3) return null;
    if (site != null && parts[0] != site) return null;
    final match = _bancadaSegment.firstMatch(parts[1]);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Chave interna do app (`bancada-02`) a partir do tópico.
  static String? extractDeviceId(String topic, {String? site}) {
    final bancada = extractBancadaNum(topic, site: site);
    if (bancada == null) return null;
    return bancadaSegment(bancada);
  }

  static String? extractDeviceIdFromPayload(Map<String, dynamic> json) {
    final deviceId = json['device_id'] as String?;
    if (deviceId != null && deviceId.isNotEmpty) return deviceId;
    final bancada = (json['bancada'] as num?)?.toInt();
    if (bancada != null) return bancadaSegment(bancada);
    return null;
  }
}
