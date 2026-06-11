import 'dart:convert';

import 'models/mqtt_messages.dart';

class MqttParseException implements Exception {
  MqttParseException(this.message);
  final String message;

  @override
  String toString() => 'MqttParseException: $message';
}

class MqttParser {
  static Map<String, dynamic>? tryParseJson(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  static HeartbeatMessage? parseHeartbeat(String payload) {
    final json = tryParseJson(payload);
    if (json == null) return null;
    return HeartbeatMessage(
      uptime: (json['uptime'] as num?)?.toInt() ?? 0,
      rssi: (json['rssi'] as num?)?.toInt() ?? 0,
      estado: DeviceFsmState.fromString(json['estado'] as String?),
      fila: (json['fila'] as num?)?.toInt() ?? 0,
      firmwareVersion: json['firmware_version'] as String? ?? '',
    );
  }

  static TestResultMessage? parseTestResult(Map<String, dynamic> json) {
    if (json['tipo'] != 'teste') return null;
    return TestResultMessage(
      numeroOp: json['numero_op'] as String? ?? '',
      idProduto: json['id_produto'] as String? ?? '',
      ano: json['ano'] as String? ?? '',
      veredito: json['veredito'] as String? ?? '',
      potenciaMedia: (json['potencia_media'] as num?)?.toDouble() ?? 0,
      sequencial: (json['sequencial'] as num?)?.toInt() ?? 0,
      aprovadosNoLote: (json['aprovados_no_lote'] as num?)?.toInt() ?? 0,
    );
  }

  static RejectionMessage? parseRejection(Map<String, dynamic> json) {
    if (json['tipo'] != 'rejeicao') return null;
    return RejectionMessage(motivo: json['motivo'] as String? ?? 'desconhecido');
  }

  static OtaStatusMessage? parseOtaStatus(Map<String, dynamic> json) {
    if (json['tipo'] != 'ota') return null;
    return OtaStatusMessage(
      evento: json['evento'] as String? ?? '',
      detalhe: json['detalhe'] as String?,
    );
  }

  static CalibrationSampleMessage? parseCalibrationSample(String payload) {
    final json = tryParseJson(payload);
    if (json == null) return null;
    if (json['tipo'] != 'calibracao_amostra') return null;
    return CalibrationSampleMessage(
      potenciaW: (json['potencia_w'] as num?)?.toDouble() ?? 0,
      elapsedMs: (json['elapsed_ms'] as num?)?.toInt() ?? 0,
    );
  }

  static CalibrationMessage? parseCalibration(String payload) {
    final json = tryParseJson(payload);
    if (json == null) return null;
    if (json['tipo'] != 'calibracao') return null;
    return CalibrationMessage(
      potenciaMedia: (json['potencia_media'] as num?)?.toDouble() ?? 0,
    );
  }

  static HardwareAlertMessage? parseHardwareAlert(String payload) {
    final json = tryParseJson(payload);
    if (json == null) return null;
    if (json['tipo'] != 'hardware') return null;
    return HardwareAlertMessage(
      falha: json['falha'] as String?,
      evento: json['evento'] as String?,
    );
  }
}
