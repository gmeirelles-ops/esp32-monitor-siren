## MODIFIED Requirements

### Requirement: Consulta de histórico por serial
O app SHALL expor consulta ao histórico local de testes associados a um número de série (e por OP), agregando tentativas e metadados. O app SHALL NOT depender de buffer de etiquetas ZPL para rastreabilidade.

#### Scenario: Busca por serial
- **WHEN** o gestor busca um serial conhecido
- **THEN** o app retorna registros de `test_results` desse serial ordenados por data

### Requirement: Serial ITF sem buffer ZPL
O cálculo do dígito verificador ITF e a montagem do serial SHALL ocorrer no app; após unicidade OK, o app SHALL enfileirar gravação laser. O app SHALL NOT adicionar o serial a buffer de etiquetas.

#### Scenario: Aprovado único
- **WHEN** aprovação gera serial inédito
- **THEN** o app registra o teste e enfileira na `mark_queue`

#### Scenario: Duplicado
- **WHEN** o serial já existe localmente
- **THEN** o app não enfileira gravação e sinaliza conflito
