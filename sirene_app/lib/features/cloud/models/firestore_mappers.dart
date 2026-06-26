import '../../../core/database/database.dart';
import '../../mqtt/models/mqtt_messages.dart';

/// Subcoleções em `test_results/{numero_op}/`.
const firestoreSubcollectionSeriais = 'seriais';
const firestoreSubcollectionReprovadas = 'reprovadas';

/// Legado flat — mantido para entradas antigas na fila.
String testResultDocumentId(String numeroOp, int sequencial) =>
    '${numeroOp}_$sequencial';

String lotePath(String numeroOp) => 'test_results/$numeroOp';

String serialPath(String numeroOp, String serial) =>
    'test_results/$numeroOp/$firestoreSubcollectionSeriais/$serial';

String reprovadaPath(String numeroOp, int sequencial) =>
    'test_results/$numeroOp/$firestoreSubcollectionReprovadas/$sequencial';

bool isTesteAprovado(TestResultMessage test) =>
    test.veredito.toUpperCase() == 'APROVADO';

Map<String, dynamic> mapLoteDocument({
  required BatchConfig batch,
  required String deviceId,
  required String status,
  required String stationId,
  required DateTime startedAt,
  DateTime? endedAt,
  int? aprovados,
  int? reprovados,
}) {
  return {
    'numero_op': batch.numeroOp,
    'id_produto': batch.idProduto,
    'ano': batch.ano,
    'quantidade_total': batch.quantidadeTotal,
    'device_id': deviceId,
    'status': status,
    'station_id': stationId,
    'started_at': startedAt.toUtc().toIso8601String(),
    'tempo_teste_sec': batch.tempoTeste,
    'potencia_min': batch.potenciaMin,
    'potencia_max': batch.potenciaMax,
    if (endedAt != null) 'ended_at': endedAt.toUtc().toIso8601String(),
    if (aprovados != null) 'aprovados': aprovados,
    if (reprovados != null) 'reprovados': reprovados,
  };
}

/// Merge parcial do lote após um teste (contadores/metadata).
Map<String, dynamic> mapLoteTestPatch({
  required String numeroOp,
  required String stationId,
  required TestResultMessage test,
}) {
  return {
    'numero_op': numeroOp,
    'station_id': stationId,
    'id_produto': test.idProduto,
    'ano': test.ano,
    if (isTesteAprovado(test)) 'aprovados': test.aprovadosNoLote,
  };
}

Map<String, dynamic> mapSerialDocument({
  required String deviceId,
  required TestResultMessage test,
  required String serial,
  String? operador,
  String? operatorCodigo,
  required String stationId,
  required DateTime timestamp,
  int? tempoTesteSec,
  double? potenciaMin,
  double? potenciaMax,
  bool isRetest = false,
}) {
  return {
    'device_id': deviceId,
    'numero_op': test.numeroOp,
    'id_produto': test.idProduto,
    'ano': test.ano,
    'veredito': test.veredito,
    'potencia_media': test.potenciaMedia,
    'sequencial': test.sequencial,
    'serial': serial,
    if (operador != null) 'operador': operador,
    if (operatorCodigo != null) 'operator_codigo': operatorCodigo,
    if (tempoTesteSec != null) 'tempo_teste_sec': tempoTesteSec,
    if (potenciaMin != null) 'potencia_min': potenciaMin,
    if (potenciaMax != null) 'potencia_max': potenciaMax,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'station_id': stationId,
    'is_retest': isRetest,
  };
}

Map<String, dynamic> mapReprovadaDocument({
  required String deviceId,
  required TestResultMessage test,
  String? operador,
  String? operatorCodigo,
  required String stationId,
  required DateTime timestamp,
  int? tempoTesteSec,
  double? potenciaMin,
  double? potenciaMax,
  bool isRetest = false,
}) {
  return {
    'device_id': deviceId,
    'numero_op': test.numeroOp,
    'id_produto': test.idProduto,
    'ano': test.ano,
    'veredito': test.veredito,
    'potencia_media': test.potenciaMedia,
    'sequencial': test.sequencial,
    if (operador != null) 'operador': operador,
    if (operatorCodigo != null) 'operator_codigo': operatorCodigo,
    if (tempoTesteSec != null) 'tempo_teste_sec': tempoTesteSec,
    if (potenciaMin != null) 'potencia_min': potenciaMin,
    if (potenciaMax != null) 'potencia_max': potenciaMax,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'station_id': stationId,
    'is_retest': isRetest,
  };
}

@Deprecated('Use mapSerialDocument or mapReprovadaDocument')
Map<String, dynamic> mapTestResult({
  required String deviceId,
  required TestResultMessage test,
  String? serial,
  String? operador,
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
    if (operador != null) 'operador': operador,
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

@Deprecated('Use mapLoteDocument — lotes vão em test_results/{numero_op}')
Map<String, dynamic> mapBatch({
  required BatchConfig batch,
  required String deviceId,
  required String status,
  required String stationId,
  required DateTime startedAt,
  DateTime? endedAt,
  int? aprovados,
}) {
  return mapLoteDocument(
    batch: batch,
    deviceId: deviceId,
    status: status,
    stationId: stationId,
    startedAt: startedAt,
    endedAt: endedAt,
    aprovados: aprovados,
  );
}

typedef ParsedProduct = ({
  String idProduto,
  String nome,
  double potenciaRef,
  double potenciaMin,
  double potenciaMax,
  double toleranciaPct,
  int tempoTesteSec,
  DateTime? calibradoEm,
  String? calibradoDeviceId,
});

double _asDouble(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _asInt(Object? v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

DateTime? _asDateTime(Object? v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Converte um documento `products` do Firestore em produto local.
ParsedProduct? productFromFirestore(Map<String, dynamic> data) {
  final idProduto = data['id_produto'];
  if (idProduto is! String || idProduto.isEmpty) return null;
  return (
    idProduto: idProduto,
    nome: (data['nome'] as String?) ?? '',
    potenciaRef: _asDouble(data['potencia_ref']),
    potenciaMin: _asDouble(data['potencia_min']),
    potenciaMax: _asDouble(data['potencia_max']),
    toleranciaPct: _asDouble(data['tolerancia_pct']),
    tempoTesteSec: _asInt(data['tempo_teste_sec']),
    calibradoEm: _asDateTime(data['calibrado_em']),
    calibradoDeviceId: data['calibrado_device_id'] as String?,
  );
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

typedef ParsedOperator = ({
  String codigo,
  String nome,
  bool ativo,
  bool isGestor,
  DateTime updatedAt,
});

ParsedOperator? operatorFromFirestore(Map<String, dynamic> data) {
  final codigo = data['codigo'];
  if (codigo is! String || codigo.isEmpty) return null;
  return (
    codigo: codigo,
    nome: (data['nome'] as String?) ?? '',
    ativo: data['ativo'] is bool ? data['ativo'] as bool : true,
    isGestor: data['is_gestor'] is bool ? data['is_gestor'] as bool : false,
    updatedAt: _asDateTime(data['updated_at']) ?? DateTime.now().toUtc(),
  );
}

Map<String, dynamic> mapOperator({
  required Operator operator,
  required DateTime updatedAt,
}) {
  return {
    'codigo': operator.codigo,
    'nome': operator.nome,
    'ativo': operator.ativo,
    'is_gestor': operator.isGestor,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}
