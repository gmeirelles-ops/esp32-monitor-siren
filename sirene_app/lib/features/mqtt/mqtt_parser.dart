import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/constants/mqtt_protocol.dart';
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

  /// Remove artefatos de JSON colado (ex.: `","","` sem chave, aspas duplicadas).
  @visibleForTesting
  static String sanitizeCorruptedJson(String json) {
    var s = json.replaceAll(',"",', ',');
    s = s.replaceAllMapped(
      RegExp(r'"(numero_op|id_produto|ano)"\s*:\s*"([^"]*?)""+'),
      (m) => '"${m[1]}":"${m[2]}"',
    );
    return s;
  }

  /// Extrai campos de teste via regex quando JSON está colado/inválido (produção OP 1001).
  @visibleForTesting
  static Map<String, dynamic>? recoverTestFields(String payload) {
    final vereditoRe = RegExp(r'"veredito"\s*:\s*"(APROVADO|REPROVADO)"', caseSensitive: false);
    final vereditoMatches = vereditoRe.allMatches(payload);
    if (vereditoMatches.isEmpty) return null;

    final veredito = vereditoMatches.last.group(1)!.toUpperCase();
    final potencia = _lastDouble(payload, r'"potencia_media"\s*:\s*([\d.]+)');
    final sequencial = _lastInt(payload, r'"sequencial"\s*:\s*(\d+)');
    final aprovados = _lastInt(payload, r'"aprovados_no_lote"\s*:\s*(\d+)');
    final tsMs = _lastInt(payload, r'"ts_ms"\s*:\s*(\d+)');
    final tsUnix = _lastInt(payload, r'"ts_unix"\s*:\s*(\d+)');
    if (sequencial == null || sequencial <= 0 || potencia == null) return null;

    final numeroOp = _lastString(payload, r'"numero_op"\s*:\s*"([^"{\\]+)');
    final idProduto = _extractIdProduto(payload);
    final ano = _extractAno(payload);

    return {
      'tipo': 'teste',
      'veredito': veredito,
      'potencia_media': potencia,
      'sequencial': sequencial,
      'aprovados_no_lote': aprovados ?? 0,
      if (tsMs != null) 'ts_ms': tsMs,
      if (tsUnix != null) 'ts_unix': tsUnix,
      if (numeroOp != null && numeroOp.isNotEmpty) 'numero_op': numeroOp,
      if (idProduto != null && idProduto.isNotEmpty) 'id_produto': idProduto,
      if (ano != null && ano.isNotEmpty) 'ano': ano,
    };
  }

  static String? _lastString(String payload, String pattern) {
    final matches = RegExp(pattern).allMatches(payload);
    if (matches.isEmpty) return null;
    return matches.last.group(1);
  }

  static int? _lastInt(String payload, String pattern) {
    final s = _lastString(payload, pattern);
    return s == null ? null : int.tryParse(s);
  }

  static double? _lastDouble(String payload, String pattern) {
    final s = _lastString(payload, pattern);
    return s == null ? null : double.tryParse(s);
  }

  static String? _sanitizeIdProduto(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final digits = RegExp(r'\d{1,3}').stringMatch(raw);
    return digits;
  }

  static String? _extractIdProduto(String payload) {
    final digitMatches = RegExp(r'"id_produto"\s*:\s*"(\d{1,3})').allMatches(payload);
    if (digitMatches.isNotEmpty) {
      return digitMatches.last.group(1);
    }
    final matches = RegExp(r'"id_produto"\s*:\s*"([^"]*)').allMatches(payload);
    String? best;
    for (final m in matches) {
      final candidate = _sanitizeIdProduto(m.group(1));
      if (candidate != null && (best == null || candidate.length >= best.length)) {
        best = candidate;
      }
    }
    return best;
  }

  static String? _extractAno(String payload) {
    final matches = RegExp(r'"ano"\s*:\s*"(\d{0,2})').allMatches(payload);
    for (final m in matches) {
      final candidate = _sanitizeAno(m.group(1));
      if (candidate != null) return candidate;
    }
    return _sanitizeAno(_lastString(payload, r'"ano"\s*:\s*"(\d{0,2})'));
  }

  static String? _sanitizeAno(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final digits = RegExp(r'\d{2}').firstMatch(raw)?.group(0);
    return digits;
  }

  /// Extrai **todos** os `tipo:teste` de um payload colado (não só o último).
  static List<Map<String, dynamic>> tryParseAllTestObjects(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return const [];

    const marker = '{"tipo":"teste"';
    final indices = <int>[];
    var from = 0;
    while (true) {
      final idx = trimmed.indexOf(marker, from);
      if (idx < 0) break;
      indices.add(idx);
      from = idx + marker.length;
    }

    if (indices.isEmpty) {
      final whole = tryParseJson(trimmed) ?? tryParseJson(sanitizeCorruptedJson(trimmed));
      if (whole != null && whole['tipo'] == 'teste') {
        return [whole];
      }
      if (trimmed.contains('"veredito"')) {
        return _recoverAllTestFields(trimmed);
      }
      return const [];
    }

    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < indices.length; i++) {
      final start = indices[i];
      final endExclusive = i + 1 < indices.length ? indices[i + 1] : trimmed.length;
      final chunk = trimmed.substring(start, endExclusive);
      final lastBrace = chunk.lastIndexOf('}');
      if (lastBrace < 0) continue;

      var candidate = sanitizeCorruptedJson(chunk.substring(0, lastBrace + 1));
      var parsed = tryParseJson(candidate);
      if (parsed == null || parsed['tipo'] != 'teste') {
        parsed = recoverTestFields(chunk);
      } else {
        _enrichTestObject(parsed, chunk, fullPayload: trimmed);
        final ano = parsed['ano'];
        if (ano == null || (ano is String && ano.isEmpty)) {
          final inferred = _inferAnoFromGluedPrefix(trimmed, start);
          if (inferred != null) parsed['ano'] = inferred;
        }
      }
      if (parsed != null && parsed['tipo'] == 'teste' && parseTestResult(parsed) != null) {
        results.add(parsed);
      }
    }

    if (results.isEmpty && trimmed.contains('"veredito"')) {
      return _recoverAllTestFields(trimmed);
    }
    return _dedupeTestMaps(results);
  }

  static List<Map<String, dynamic>> _recoverAllTestFields(String payload) {
    final vereditoRe =
        RegExp(r'"veredito"\s*:\s*"(APROVADO|REPROVADO)"', caseSensitive: false);
    final results = <Map<String, dynamic>>[];
    for (final m in vereditoRe.allMatches(payload)) {
      final start = (m.start - 160).clamp(0, payload.length);
      final end = (m.end + 120).clamp(0, payload.length);
      final chunk = payload.substring(start, end);
      final recovered = recoverTestFields(chunk);
      if (recovered != null) results.add(recovered);
    }
    return _dedupeTestMaps(results);
  }

  static List<Map<String, dynamic>> _dedupeTestMaps(List<Map<String, dynamic>> maps) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final m in maps) {
      final key =
          '${m['ts_ms']}_${m['sequencial']}_${m['veredito']}_${m['potencia_media']}';
      if (seen.add(key)) out.add(m);
    }
    return out;
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

    if (trimmed.contains('"veredito"')) {
      final recovered = recoverTestFields(trimmed);
      if (recovered != null) return [recovered];
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
    var candidate = tail.substring(0, end + 1);
    candidate = sanitizeCorruptedJson(candidate);
    final parsed =
        tryParseJson(candidate) ?? tryParseJson(sanitizeCorruptedJson(candidate));
    if (parsed == null) return null;

    if (tipo == 'teste') {
      _enrichTestObject(parsed, payload, fullPayload: payload);
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

  static void _enrichTestObject(
    Map<String, dynamic> obj,
    String chunk, {
    String? fullPayload,
  }) {
    final recovered = recoverTestFields(fullPayload ?? chunk);
    if (recovered == null) return;
    for (final key in ['id_produto', 'ano', 'numero_op', 'ts_ms', 'aprovados_no_lote']) {
      final v = obj[key];
      if ((v == null || (v is String && v.isEmpty)) && recovered[key] != null) {
        obj[key] = recovered[key];
      }
    }
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
    final ultimoVeredito = (json['ultimo_veredito'] as String?)?.trim().toUpperCase();
    return HeartbeatMessage(
      uptime: (json['uptime'] as num?)?.toInt() ?? 0,
      rssi: (json['rssi'] as num?)?.toInt() ?? 0,
      estado: DeviceFsmState.fromString(json['estado'] as String?),
      fila: (json['fila'] as num?)?.toInt() ?? 0,
      firmwareVersion: json['firmware_version'] as String? ?? '',
      deviceId: json['device_id'] as String?,
      bancada: (json['bancada'] as num?)?.toInt(),
      site: json['site'] as String?,
      numeroOp: json['numero_op'] as String?,
      aprovados: (json['aprovados'] as num?)?.toInt(),
      proximoSequencial: (json['proximo_sequencial'] as num?)?.toInt(),
      ultimoVeredito: ultimoVeredito != null && ultimoVeredito.isNotEmpty ? ultimoVeredito : null,
      ultimaPotencia: (json['ultima_potencia'] as num?)?.toDouble(),
      ultimoSequencial: (json['ultimo_sequencial'] as num?)?.toInt(),
      ultimoTsMs: (json['ultimo_ts_ms'] as num?)?.toInt(),
      batchNvsFault: _parseJsonBool(json['batch_nvs_fault']),
      protocolVersion: (json['protocol_version'] as num?)?.toInt(),
    );
  }

  static bool _parseJsonBool(Object? value) {
    if (value == true) return true;
    if (value is num && value != 0) return true;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  /// True se o firmware reporta versão de protocolo incompatível com o app.
  static bool isProtocolMismatch(HeartbeatMessage hb) =>
      !mqttProtocolMatches(hb.protocolVersion);

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
      tsMs: (json['ts_ms'] as num?)?.toInt(),
      tsUnix: (json['ts_unix'] as num?)?.toInt(),
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
    if (!json.containsKey('potencia_media') && !json.containsKey('potencia_max')) return null;
    return CalibrationMessage(
      potenciaMedia:
          (json['potencia_media'] as num?)?.toDouble() ??
          (json['potencia_max'] as num?)?.toDouble() ??
          0,
      potenciaMax: (json['potencia_max'] as num?)?.toDouble(),
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
