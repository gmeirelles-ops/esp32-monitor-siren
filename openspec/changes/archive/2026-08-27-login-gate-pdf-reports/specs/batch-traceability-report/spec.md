## ADDED Requirements

### Requirement: Lista de lotes no relatório
O app SHALL exibir na tela Relatório uma lista de lotes (OP) com totais de testes, aprovados, reprovados e yield, ordenados pelo teste mais recente.

#### Scenario: Lotes visíveis
- **WHEN** o operador autenticado abre a tela Relatório
- **THEN** o app lista os lotes com testes no período e filtros selecionados

#### Scenario: Lote sem testes no filtro
- **WHEN** nenhum lote corresponde aos filtros
- **THEN** o app informa que nenhum lote foi encontrado

### Requirement: Detalhe do lote com sirenes testadas
O app SHALL permitir abrir um lote da lista e exibir todas as sirenes (testes) daquela OP.

#### Scenario: Drill-down do lote
- **WHEN** o operador seleciona um lote na lista
- **THEN** o app exibe lista de testes com serial, veredito, potência, dispositivo, operador e data

### Requirement: Filtros do relatório
O relatório SHALL oferecer filtros por período, OP, produto, dispositivo e veredito (no detalhe).

#### Scenario: Filtro por veredito no detalhe
- **WHEN** o operador seleciona apenas aprovados no detalhe do lote
- **THEN** a lista exibe somente testes com veredito aprovado

### Requirement: Exportação CSV complementar
O app SHALL manter exportação CSV da lista de lotes e do detalhe, respeitando os filtros ativos.

#### Scenario: Exportar CSV do lote
- **WHEN** o operador aciona exportação CSV no detalhe
- **THEN** o app grava arquivo CSV com os testes filtrados
