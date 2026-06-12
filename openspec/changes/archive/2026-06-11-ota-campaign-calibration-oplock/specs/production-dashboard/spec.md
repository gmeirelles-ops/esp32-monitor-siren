## ADDED Requirements

### Requirement: Feed de alertas de hardware recentes
O painel SHALL exibir um feed dos alertas de hardware mais recentes registrados localmente, para que o supervisor possa agir sobre falhas.

#### Scenario: Alertas recentes listados
- **WHEN** existem falhas de hardware registradas
- **THEN** o painel lista os alertas mais recentes com dispositivo, tipo de falha e instante

#### Scenario: Sem alertas
- **WHEN** não há falhas de hardware registradas
- **THEN** o painel indica que não há alertas recentes
