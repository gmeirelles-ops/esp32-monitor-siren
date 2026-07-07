import 'dart:convert';

import 'package:flutter/foundation.dart';

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

  /// Remove artefatos de JSON colado (ex.: `","","` sem chave).
  @visibleForTesting
  static String sanitizeCorruptedJson(String json) {
    return json.replaceAll(',"",', ',');
  }

  /// Quando o broker entrega JSON colado/corrompido, tenta recuperar o último objeto válido.
  static List<Map<String, dynamic>> tryParseJsonObjects(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return const [];

    final whole = tryParseJson(trimmed) ?? tryParseJson(sanitizeCorruptedJson(trimmed));
    if (whole != null) return [whole];

    // Um payload MQTT = um evento lógico; prioridade teste > rejeição > batch.
    for (final tipo in [
      'teste',
      'rejeicao',
      'batch',
      'ota',
      'pzem',
      'wifi',
      'station',
      'ensaio',
    ]) {
      final obj = _tryParseLastTypedObject(trimmed, tipo);
      if (obj != null) return [obj];
    }
    return const [];
  }

  static Map<String, dynamic>? _tryParseLastTypedObject(String payload, String tipo) {
    final marker = '{"tipo":"$tipo"';
    var idx = -1;
    var searchFrom = 0;
    while (true) {
      final found = payload.indexOf(marker, searchFrom);
      if (found < 0) break;
      idx = found;
      searchFrom = found + marker.length;
    }
    if (idx < 0) return null;

    final tail = payload.substring(idx);
    final end = tail.lastIndexOf('}');
    if (end < 0) return null;
    final candidate = tail.substring(0, end + 1);
    final parsed =
        tryParseJson(candidate) ?? tryParseJson(sanitizeCorruptedJson(candidate));
    if (parsed == null) return null;

    if (tipo == 'teste') {
      final ano = parsed['ano'];
      if (ano == null || (ano is String && ano.isEmpty)) {
        final inferred = _inferAnoFromGluedPrefix(payload, idx);
        if (inferred != null) {
          parsed['ano'] = inferred;
        }
      }
    }
    return parsed;
  }

  /// Recupera `ano` do primeiro objeto quando dois JSONs de teste vêm colados.
  static String? _inferAnoFromGluedPrefix(String payload, int objectStart) {
    final prefix = payload.substring(0, objectStart);
    final anchor = prefix.lastIndexOf('"ano":"');
    if (anchor < 0) return null;
    final digits = StringBuffer();
    for (var i = anchor + '"ano":"'.length; i < prefix.length && digits.length < 2; i++) {
      final code = prefix.codeUnitAt(i);
      if (code < 0x30 || code > 0x39) break;
      digits.writeCharCode(code);
    }
    return digits.length == 2 ? digits.toString() : null;
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
      deviceId: json['device_id'] as String?,
      bancada: (json['bancada'] as num?)?.toInt(),
      site: json['site'] as String?,
    );
  }

  static TestResultMessage? parseTestResult(Map<String, dynamic> json) {
    if (json['tipo'] != 'teste') return null;
    final veredito = (json['veredito'] as String? ?? '').trim().toUpperCase();
    if (veredito != 'APROVADO' && veredito != 'REPROVADO') return null;
    final sequencial = (json['sequencial'] as num?)?.toInt() ?? 0;
    if (sequencial <= 0) return null;
    return TestResultMessage(
      numeroOp: json['numero_op'] as String? ?? '',
      idProduto: json['id_produto'] as String? ?? '',
      ano: json['ano'] as String? ?? '',
      veredito: veredito,
      potenciaMedia: (json['potencia_media'] as num?)?.toDouble() ?? 0,
      sequencial: sequencial,
      aprovadosNoLote: (json['aprovados_no_lote'] as num?)?.toInt() ?? 0,
    );
  }

  static RejectionMessage? parseRejection(Map<String, dynamic> json) {
    if (json['tipo'] != 'rejeicao') return null;
    return RejectionMessage(motivo: json['motivo'] as String? ?? 'desconhecido');
  }

  static BatchEventMessage? parseBatchEvent(Map<String, dynamic> json) {
    if (json['tipo'] != 'batch') return null;
    return BatchEventMessage(
      evento: json['evento'] as String? ?? '',
      numeroOp: json['numero_op'] as String?,
      motivo: json['motivo'] as String?,
      estado: json['estado'] as String?,
    );
  }

  static NvsFaultAlertMessage? parseNvsFaultAlert(String payload) {
    final json = tryParseJson(payload);
    if (json == null) return null;
    if (json['tipo'] != 'alerta') return null;
    final evento = json['evento'] as String? ?? '';
    if (evento != 'batch_nvs_fault') return null;
    return NvsFaultAlertMessage(
      evento: evento,
      detalhe: json['detalhe'] as String?,
    );
  }

  static OtaStatusMessage? parseOtaStatus(Map<String, dynamic> json, {String? deviceId}) {
    if (json['tipo'] != 'ota') return null;
    return OtaStatusMessage(
      evento: json['evento'] as String? ?? '',
      detalhe: json['detalhe'] as String?,
      deviceId: deviceId,
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
    final evento = json['evento'] as String?;
    if (evento != null && evento != 'concluido') return null;
    if (!json.containsKey('potencia_media')) return null;
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

  static EnsaioStatusMessage? parseEnsaioStatus(Map<String, dynamic> json) {
    if (json['tipo'] != 'ensaio') return null;
    return EnsaioStatusMessage(
      evento: json['evento'] as String? ?? '',
      n: (json['n'] as num?)?.toInt(),
      fase: json['fase'] as String?,
      elapsedSec: (json['elapsed_sec'] as num?)?.toInt() ?? 0,
      ciclos: (json['ciclos'] as num?)?.toInt() ?? 0,
      motivo: json['motivo'] as String?,
      onSec: (json['on_sec'] as num?)?.toInt(),
      offSec: (json['off_sec'] as num?)?.toInt(),
      duracaoTotalSec: (json['duracao_total_sec'] as num?)?.toInt(),
    );
  }

  static EnsaioStatusMessage? parseEnsaioPayload(String payload) {
    final json = tryParseJson(payload);
    if (json == null) return null;
    return parseEnsaioStatus(json);
  }
}
