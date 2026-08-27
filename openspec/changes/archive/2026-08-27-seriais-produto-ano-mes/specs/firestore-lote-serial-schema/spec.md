## ADDED Requirements

### Requirement: Espelho no catálogo temporal na aprovação
Quando a sincronização estiver habilitada e um teste aprovado com serial for enfileirado, o app SHALL também enfileirar `set` em `seriais/{id_produto}/anos/{YYYY}/meses/{MM}/itens/{serial}` com o mesmo payload do documento em `test_results/{numero_op}/seriais/{serial}`.

#### Scenario: Path adicional enfileirado
- **WHEN** `enqueueTestResult` processa aprovação com serial e sync ativo
- **THEN** a fila contém a entrada do path por lote e a entrada do path de catálogo temporal

#### Scenario: Sync desabilitado
- **WHEN** sync não está ativo
- **THEN** nenhuma das entradas de serial é enfileirada
