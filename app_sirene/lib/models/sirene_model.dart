/// Modelo de sirene (`Modelos_Sirenes` no Firestore).
///
/// Corrente e potência em inteiros brutos (escala aplicada na UI).
class SireneModel {
  const SireneModel({
    required this.idModelo,
    required this.nome,
    required this.correnteMinima,
    required this.correnteMaxima,
    required this.potenciaMinima,
    required this.potenciaMaxima,
  });

  final String idModelo;
  final String nome;
  final int correnteMinima;
  final int correnteMaxima;
  final int potenciaMinima;
  final int potenciaMaxima;

  factory SireneModel.fromMap(Map<String, dynamic> map) {
    return SireneModel(
      idModelo: map['id_modelo'] as String? ?? '',
      nome: map['nome_modelo'] as String? ?? map['nome'] as String? ?? '',
      correnteMinima: _asInt(map['corrente_minima_a'] ?? map['correnteMinima']),
      correnteMaxima: _asInt(map['corrente_maxima_a'] ?? map['correnteMaxima']),
      potenciaMinima: _asInt(map['potencia_minima_w'] ?? map['potenciaMinima']),
      potenciaMaxima: _asInt(map['potencia_maxima_w'] ?? map['potenciaMaxima']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id_modelo': idModelo,
        'nome_modelo': nome,
        'corrente_minima_a': correnteMinima,
        'corrente_maxima_a': correnteMaxima,
        'potencia_minima_w': potenciaMinima,
        'potencia_maxima_w': potenciaMaxima,
      };

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }
}
