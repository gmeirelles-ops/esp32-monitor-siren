# batch-live-dashboard Specification

## Purpose
TBD - created by archiving change batch-live-dashboard. Update Purpose after archive.
## Requirements
### Requirement: Navegação para dashboard após configurar lote
O app SHALL navegar para a tela de acompanhamento ao vivo do lote imediatamente após `SET_BATCH` ser aceito (sem rejeição MQTT).

#### Scenario: Transição após SET_BATCH bem-sucedido
- **WHEN** o operador confirma "Configurar lote" e o comando não é rejeitado
- **THEN** o app abre a tela Batch Live Dashboard para a OP e dispositivo configurados

#### Scenario: SET_BATCH rejeitado
- **WHEN** o firmware rejeita `SET_BATCH`
- **THEN** o app permanece na tela de configuração e exibe o motivo da rejeição, sem abrir o dashboard

### Requirement: Cabeçalho e contexto do lote
A tela Batch Live Dashboard SHALL exibir OP, produto (`id_produto` e nome), dispositivo, estado FSM atual, limites de potência, meta (`quantidade_total`) e operador (e-mail autenticado ou indicação de operação local).

#### Scenario: Informações do lote visíveis
- **WHEN** o dashboard é aberto para um lote ativo
- **THEN** o app exibe OP, produto, dispositivo, estado FSM, potência mín/máx, meta e operador

### Requirement: Métricas de progresso do lote
O app SHALL calcular e exibir aprovados, reprovados, total testado, yield (%) e peças pendentes até a meta, com base nos testes gravados para a OP corrente no SQLite.

#### Scenario: Contadores atualizados após novo teste
- **WHEN** um novo resultado de teste é gravado para a OP exibida
- **THEN** os contadores e o yield são recalculados e atualizados na tela sem recarga manual

#### Scenario: Barra de progresso da meta
- **WHEN** `quantidade_total` é maior que zero
- **THEN** o app exibe barra de progresso com `aprovados / quantidade_total`

### Requirement: Gráfico de potência por teste
O app SHALL exibir gráfico dos últimos testes da OP com potência média no eixo de valor e sequencial ou ordem cronológica no eixo horizontal, colorindo barras ou pontos por veredito (aprovado/reprovado) e indicando visualmente os limites `potencia_min` e `potencia_max`.

#### Scenario: Gráfico com testes aprovados e reprovados
- **WHEN** existem testes aprovados e reprovados na OP
- **THEN** o gráfico distingue visualmente cada veredito e mostra a faixa aceitável de potência

#### Scenario: Sem testes ainda
- **WHEN** nenhum teste foi gravado para a OP
- **THEN** o app exibe estado vazio orientando pressionar o botão no dispositivo ou usar simulador de desenvolvimento

### Requirement: Lista cronológica de testes do lote
O app SHALL listar os testes da OP corrente em ordem cronológica decrescente, mostrando sequencial, veredito, potência média, serial (se houver) e horário.

#### Scenario: Item de teste aprovado na lista
- **WHEN** um teste aprovado com serial é gravado
- **THEN** a lista exibe sequencial, veredito APROVADO, potência, serial e timestamp

### Requirement: Indicadores de estado e ações do lote
O dashboard SHALL refletir `BATCH_READY` e `TESTING` com indicadores visuais distintos e SHALL oferecer ação "Encerrar lote" (`END_BATCH`) com confirmação.

#### Scenario: Aguardando botão físico
- **WHEN** o dispositivo está em `BATCH_READY`
- **THEN** o dashboard exibe instrução para pressionar o botão no dispositivo

#### Scenario: Encerramento do lote no dashboard
- **WHEN** o operador confirma "Encerrar lote" no dashboard e o comando não é rejeitado
- **THEN** o app envia `END_BATCH`, atualiza estado para IDLE e retorna à tela de configuração ou exibe lote encerrado

### Requirement: Atalho para lote em andamento
Quando um dispositivo selecionado possui lote ativo, a tela de configuração SHALL exibir atalho para abrir o Batch Live Dashboard da OP corrente.

#### Scenario: Retomar acompanhamento
- **WHEN** o operador abre a tela de Lote e o dispositivo já tem `activeBatch`
- **THEN** o app oferece botão ou banner "Ver lote em andamento" que abre o dashboard

### Requirement: Seriais emitidos no lote corrente
O Batch Live Dashboard SHALL exibir a lista de seriais já emitidos (aprovados com serial) para a OP em acompanhamento, em ordem de sequencial crescente.

#### Scenario: Quatro seriais após quatro aprovações
- **WHEN** quatro testes aprovados com serial foram gravados para a OP exibida
- **THEN** o dashboard lista os quatro seriais com seus sequenciais

#### Scenario: Serial pendente de impressão
- **WHEN** um serial está no buffer de etiquetas da OP
- **THEN** o dashboard indica que o serial aguarda impressão (ícone ou rótulo "pendente")

