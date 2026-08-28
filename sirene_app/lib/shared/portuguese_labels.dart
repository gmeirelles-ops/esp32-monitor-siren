/// Rótulos de UI em português (glossário do app).
abstract final class PortugueseLabels {
  static const navBancadas = 'Bancadas';
  static const rendimento = 'Rendimento';
  static const rendimentoPorDia = 'Rendimento por dia (%)';
  static const totalTestadas = 'Total testadas';
  static const conectada = 'Conectada';
  static const desconectada = 'Desconectada';
  static const identificadorTecnico = 'Identificador técnico';
  static const encerrarLote = 'Encerrar lote';

  // Linguagem de chão de fábrica (evitar MQTT/jargão técnico na UI do operador).
  static const redePostoDesconectada = 'Sem conexão com a bancada';
  static const redePostoDesconectadaDetalhe =
      'Resultados não chegam ao app — verifique a rede do posto.';
  static const aguardandoResultadoBancada = 'Aguardando resultado';
  static const filaOfflineBancada = 'Fila na bancada';
}
