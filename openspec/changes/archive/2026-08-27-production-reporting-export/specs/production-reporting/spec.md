## ADDED Requirements

### Requirement: Exportação CSV de resumo de produção
O app SHALL permitir exportar para arquivo CSV o resumo de produção (total, aprovados, reprovados, yield) do período selecionado no Painel.

#### Scenario: Exportar resumo do período
- **WHEN** o supervisor seleciona um período no Painel e aciona "Exportar resumo"
- **THEN** o app grava um arquivo CSV com as métricas do período e confirma o caminho salvo

#### Scenario: Período sem dados
- **WHEN** o supervisor tenta exportar resumo sem testes no período
- **THEN** o app informa que não há dados para exportar

### Requirement: Exportação CSV de testes detalhados
O app SHALL permitir exportar a lista de resultados de teste do período com serial, número OP, veredito, potência média, operador e timestamp.

#### Scenario: Exportar testes do período
- **WHEN** o supervisor aciona "Exportar testes" no Painel
- **THEN** o app grava CSV com uma linha por teste do período selecionado

### Requirement: Exportação CSV de falhas de hardware
O app SHALL permitir exportar falhas de hardware registradas localmente no período selecionado.

#### Scenario: Exportar falhas
- **WHEN** o supervisor aciona "Exportar falhas" e existem falhas no período
- **THEN** o app grava CSV com device_id, tipo de falha e timestamp
