/// Regras de calibração alinhadas ao firmware 1.5.1+.
abstract final class DeviceCalibration {
  static const blockedStates = {
    'TESTING',
    'OTA_UPDATING',
    'PROVISIONING',
  };

  /// Firmware aceita IDLE, BATCH_READY e HARDWARE_FAULT (se PZEM OK).
  static bool canCalibrate({
    required bool deviceOnline,
    required String? estado,
  }) {
    if (!deviceOnline) return false;
    if (estado == null || estado.isEmpty) return false;
    return !blockedStates.contains(estado);
  }

  static String deviceLabel(String? name, String? deviceId, bool online, String? estado) {
    final label = name?.isNotEmpty == true ? name! : (deviceId ?? '—');
    if (!online) return '$label (Desconectado)';
    if (estado != null && estado.isNotEmpty) return '$label ($estado)';
    return label;
  }

  static String estadoHint(String? estado, bool online) {
    if (!online) {
      return 'Dispositivo offline — verifique MQTT e broker nas Configurações.';
    }
    if (estado == 'TESTING') {
      return 'Aguarde o fim do teste ou calibração em andamento.';
    }
    if (estado == 'BATCH_READY') {
      return 'Lote ativo — calibração permitida (firmware 1.5.1+).';
    }
    if (estado == 'IDLE') {
      return 'Pronto para calibrar.';
    }
    return 'Estado: ${estado ?? "—"}';
  }
}
