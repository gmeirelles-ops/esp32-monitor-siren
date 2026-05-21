/// Resultado de um ciclo de teste (Firestore ou cache Hive offline).
class TesteResult {
  const TesteResult({
    required this.idOperador,
    required this.idModelo,
    required this.lote,
    required this.correnteLida,
    required this.potenciaLida,
    required this.status,
    required this.dataHora,
    this.isSynced = false,
  });

  final String idOperador;
  final String idModelo;
  final String lote;
  final int correnteLida;
  final int potenciaLida;
  final String status;
  final DateTime dataHora;
  final bool isSynced;

  factory TesteResult.fromMap(Map<String, dynamic> map) {
    return TesteResult(
      idOperador: map['id_operador'] as String? ?? map['idOperador'] as String? ?? '',
      idModelo: map['id_modelo'] as String? ?? map['idModelo'] as String? ?? '',
      lote: map['lote'] as String? ?? '',
      correnteLida: _asInt(map['corrente_lida'] ?? map['correnteLida']),
      potenciaLida: _asInt(map['potencia_lida'] ?? map['potenciaLida']),
      status: map['status'] as String? ?? map['resultado'] as String? ?? '',
      dataHora: _asDateTime(map['data_hora'] ?? map['dataHora']),
      isSynced: map['isSynced'] as bool? ?? map['is_synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id_operador': idOperador,
        'id_modelo': idModelo,
        'lote': lote,
        'corrente_lida': correnteLida,
        'potencia_lida': potenciaLida,
        'status': status,
        'data_hora': dataHora.toUtc().toIso8601String(),
        'is_synced': isSynced,
      };

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Valores padronizados de [TesteResult.status].
abstract final class TesteStatus {
  static const String aprovado = 'APROVADO';
  static const String reprovadoSobrecorrente = 'REPROVADO_SOBRECORRENTE';
  static const String reprovadoSubcorrente = 'REPROVADO_SUBCORRENTE';
  static const String reprovadoSobrepotencia = 'REPROVADO_SOBREPOTENCIA';
  static const String reprovadoSubpotencia = 'REPROVADO_SUBPOTENCIA';
  static const String reprovadoCircuitoAberto = 'REPROVADO_CIRCUITO_ABERTO';
  static const String erroSensor = 'ERRO_SENSOR';
}
