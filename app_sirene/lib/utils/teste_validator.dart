import '../models/sirene_model.dart';
import '../models/teste_result_model.dart';

/// Avalia leituras brutas (inteiros) contra os limites do modelo.
abstract final class TesteValidator {
  static String avaliar({
    required SireneModel modelo,
    required int correnteLida,
    required int potenciaLida,
    String? statusEsp,
  }) {
    if (statusEsp == 'ERRO_SENSOR') {
      return TesteStatus.erroSensor;
    }
    if (correnteLida == 0) {
      return TesteStatus.reprovadoCircuitoAberto;
    }
    if (correnteLida < modelo.correnteMinima) {
      return TesteStatus.reprovadoSubcorrente;
    }
    if (correnteLida > modelo.correnteMaxima) {
      return TesteStatus.reprovadoSobrecorrente;
    }
    if (potenciaLida < modelo.potenciaMinima) {
      return TesteStatus.reprovadoSubpotencia;
    }
    if (potenciaLida > modelo.potenciaMaxima) {
      return TesteStatus.reprovadoSobrepotencia;
    }
    return TesteStatus.aprovado;
  }

  static bool isAprovado(String status) => status == TesteStatus.aprovado;

  static String rotuloStatus(String status) {
    switch (status) {
      case TesteStatus.aprovado:
        return 'Aprovado';
      case TesteStatus.reprovadoSobrecorrente:
        return 'Reprovado – Sobrecorrente';
      case TesteStatus.reprovadoSubcorrente:
        return 'Reprovado – Subcorrente';
      case TesteStatus.reprovadoSobrepotencia:
        return 'Reprovado – Sobrepotência';
      case TesteStatus.reprovadoSubpotencia:
        return 'Reprovado – Subpotência';
      case TesteStatus.reprovadoCircuitoAberto:
        return 'Reprovado – Circuito aberto';
      case TesteStatus.erroSensor:
        return 'Erro no sensor PZEM';
      default:
        return status;
    }
  }

  static String motivoReprovacao(String status) {
    if (isAprovado(status)) return '';
    return rotuloStatus(status);
  }
}
