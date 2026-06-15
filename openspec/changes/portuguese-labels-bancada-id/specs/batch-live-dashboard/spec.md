## MODIFIED Requirements

### Requirement: Cabeçalho e contexto do lote
A tela Batch Live Dashboard SHALL exibir OP, produto (`id_produto` e nome), bancada numerada (`Bancada N`), estado FSM em português, limites de potência, meta (`quantidade_total`) e operador.

#### Scenario: Informações do lote visíveis
- **WHEN** o dashboard é aberto para um lote ativo
- **THEN** o app exibe OP, produto, `Bancada N`, estado FSM, potência mín/máx, meta e operador com nomenclatura em português

### Requirement: Métricas de progresso do lote
O app SHALL calcular e exibir aprovadas, reprovadas, total testadas, rendimento (%) e peças pendentes até a meta, com rótulos em português.

#### Scenario: Contadores atualizados após novo teste
- **WHEN** um novo resultado de teste é gravado para a OP exibida
- **THEN** os contadores e o rendimento são recalculados e exibidos com rótulos em português
