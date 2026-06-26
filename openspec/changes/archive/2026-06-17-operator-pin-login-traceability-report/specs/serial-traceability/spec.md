## ADDED Requirements

### Requirement: Consulta de histórico completo por serial
O app SHALL expor consulta ao histórico local de testes e etiquetas associadas a um número de série, agregando todas as tentativas e metadados para exibição no relatório de rastreabilidade.

#### Scenario: Histórico agregado
- **WHEN** o relatório solicita dados para um serial existente
- **THEN** o app retorna todos os registros de `test_results` desse serial ordenados por data, mais entrada de etiqueta se houver

#### Scenario: Serial inexistente
- **WHEN** o relatório solicita dados para serial ausente no histórico
- **THEN** o app retorna resultado vazio sem erro fatal
