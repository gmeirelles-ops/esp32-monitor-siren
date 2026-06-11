abstract final class MqttTopics {
  static const prefix = 'sirene';

  static String comando(String deviceId) => '$prefix/$deviceId/comando';
  static String status(String deviceId) => '$prefix/$deviceId/status';
  static String calibracao(String deviceId) => '$prefix/$deviceId/calibracao';
  static String alerta(String deviceId) => '$prefix/$deviceId/alerta';
  static String presenca(String deviceId) => '$prefix/$deviceId/presenca';
  static String heartbeat(String deviceId) => '$prefix/$deviceId/heartbeat';

  static const subscribePresenca = '$prefix/+/presenca';
  static const subscribeHeartbeat = '$prefix/+/heartbeat';
  static const subscribeStatus = '$prefix/+/status';
  static const subscribeCalibracao = '$prefix/+/calibracao';
  static const subscribeAlerta = '$prefix/+/alerta';

  static const allSubscriptions = [
    subscribePresenca,
    subscribeHeartbeat,
    subscribeStatus,
    subscribeCalibracao,
    subscribeAlerta,
  ];

  static String? extractDeviceId(String topic) {
    final parts = topic.split('/');
    if (parts.length >= 2 && parts[0] == prefix) {
      return parts[1];
    }
    return null;
  }
}
