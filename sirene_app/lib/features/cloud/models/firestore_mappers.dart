import '../../../core/database/database.dart';
import '../../mqtt/models/mqtt_messages.dart';

String testResultDocumentId(String numeroOp, int sequencial) =>
    '${numeroOp}_$sequencial';

Map<String, dynamic> mapTestResult({
  required String deviceId,
  required TestResultMessage test,
  String? serial,
  required String stationId,
  required DateTime timestamp,
}) {
  return {
    'device_id': deviceId,
    'numero_op': test.numeroOp,
    'id_produto': test.idProduto,
    'ano': test.ano,
    'veredito': test.veredito,
    'potencia_media': test.potenciaMedia,
    'sequencial': test.sequencial,
    'aprovados_no_lote': test.aprovadosNoLote,
    if (serial != null) 'serial': serial,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'station_id': stationId,
  };
}

Map<String, dynamic> mapDevice({
  required String deviceId,
  required DeviceFsmState estado,
  required String firmwareVersion,
  required int rssi,
  required int filaOffline,
  required bool online,
  required String stationId,
  required DateTime lastSeen,
}) {
  return {
    'device_id': deviceId,
    'firmware_version': firmwareVersion,
    'last_seen': lastSeen.toUtc().toIso8601String(),
    'estado': _fsmToFirestore(estado),
    'online': online,
    'rssi': rssi,
    'fila_offline': filaOffline,
    'updated_by_station': stationId,
  };
}

String _fsmToFirestore(DeviceFsmState estado) {
  switch (estado) {
    case DeviceFsmState.provisioning:
      return 'PROVISIONING';
    case DeviceFsmState.idle:
      return 'IDLE';
    case DeviceFsmState.batchReady:
      return 'BATCH_READY';
    case DeviceFsmState.testing:
      return 'TESTING';
    case DeviceFsmState.hardwareFault:
      return 'HARDWARE_FAULT';
    case DeviceFsmState.otaUpdating:
      return 'OTA_UPDATING';
    case DeviceFsmState.unknown:
      return 'UNKNOWN';
  }
}

Map<String, dynamic> mapBatch({
  required BatchConfig batch,
  required String deviceId,
  required String status,
  required String stationId,
  required DateTime startedAt,
  DateTime? endedAt,
  int? aprovados,
}) {
  return {
    'numero_op': batch.numeroOp,
    'id_produto': batch.idProduto,
    'ano': batch.ano,
    'quantidade_total': batch.quantidadeTotal,
    'aprovados': aprovados ?? 0,
    'device_id': deviceId,
    'started_at': startedAt.toUtc().toIso8601String(),
    if (endedAt != null) 'ended_at': endedAt.toUtc().toIso8601String(),
    'status': status,
    'station_id': stationId,
  };
}

Map<String, dynamic> mapProduct({
  required Product product,
  required DateTime updatedAt,
}) {
  return {
    'id_produto': product.idProduto,
    'nome': product.nome,
    'potencia_ref': product.potenciaRef,
    'potencia_min': product.potenciaMin,
    'potencia_max': product.potenciaMax,
    'tolerancia_pct': product.toleranciaPct,
    'tempo_teste_sec': product.tempoTesteSec,
    if (product.calibradoEm != null)
      'calibrado_em': product.calibradoEm!.toUtc().toIso8601String(),
    if (product.calibradoDeviceId != null)
      'calibrado_device_id': product.calibradoDeviceId,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}
