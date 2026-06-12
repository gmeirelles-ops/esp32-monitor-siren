## MODIFIED Requirements

### Requirement: Rastreabilidade de serial por teste
O sistema SHALL associar cada serial gerado a um resultado de teste aprovado com `numero_op`, `sequencial`, `id_produto`, `ano` e timestamp, persistido localmente e consultável na tela de Consulta.

#### Scenario: Serial gravado com teste aprovado
- **WHEN** um teste é aprovado e o serial é gerado
- **THEN** o registro em `test_results` contém o serial e metadados do lote

#### Scenario: Consulta de rastreabilidade
- **WHEN** o supervisor busca um serial na tela de Consulta
- **THEN** o app exibe o histórico de testes associados a esse serial ou prefixo
