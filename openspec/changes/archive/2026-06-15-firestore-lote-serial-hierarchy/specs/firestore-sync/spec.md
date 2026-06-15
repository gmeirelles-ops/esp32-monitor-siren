## MODIFIED Requirements

### Requirement: Sincronização idempotente de resultados de teste
O app SHALL gravar testes aprovados em `test_results/{numero_op}/seriais/{serial}` e testes reprovados em `test_results/{numero_op}/reprovadas/{sequencial}`, usando upsert idempotente. O app SHALL NOT gravar novos documentos no formato flat legado `test_results/{numero_op}_{sequencial}`.

#### Scenario: Teste aprovado sincronizado
- **WHEN** o app recebe MQTT `tipo: "teste"` aprovado e grava no SQLite
- **THEN** o sync service enfileira upsert em `test_results/{numero_op}` (contadores/metadata) e `test_results/{numero_op}/seriais/{serial}` com `device_id`, `numero_op`, `veredito`, `potencia_media`, `sequencial`, `serial`, `operador` (se autenticado), `timestamp`, `station_id` e `is_retest`

#### Scenario: Teste reprovado sincronizado
- **WHEN** o app recebe MQTT `tipo: "teste"` reprovado
- **THEN** o sync service enfileira upsert em `test_results/{numero_op}` e `test_results/{numero_op}/reprovadas/{sequencial}` sem criar entrada em `seriais/`

#### Scenario: Reprocessamento do mesmo teste
- **WHEN** a mesma combinação `numero_op` + `sequencial` ou `serial` é enfileirada novamente
- **THEN** o Firestore recebe upsert no mesmo caminho de subcoleção sem duplicata

### Requirement: Sincronização de lotes
O app SHALL criar ou atualizar o documento `test_results/{numero_op}` ao configurar ou encerrar lote, consolidando metadados que antes iam para `batches/{numero_op}`. O app SHALL NOT enfileirar novos writes em `batches/`.

#### Scenario: Lote iniciado
- **WHEN** o operador envia `SET_BATCH` com sucesso
- **THEN** o sync service enfileira upsert em `test_results/{numero_op}` com `status: "active"`, campos do lote e `started_at`

#### Scenario: Lote encerrado
- **WHEN** o operador envia `END_BATCH`
- **THEN** o sync service atualiza `test_results/{numero_op}` com `status: "completed"` e `ended_at`

## ADDED Requirements

### Requirement: Caminhos de documento na fila de sync
A tabela `SyncQueue` SHALL suportar campo opcional `document_path` com caminho Firestore completo (ex.: `test_results/2026001/seriais/1232600018` ou `test_results/2026001/reprovadas/3`). Quando preenchido, o processador SHALL usar esse caminho em vez de `collection` + `document_id`.

#### Scenario: Enfileiramento de serial aprovado
- **WHEN** um teste aprovado é enfileirado para sync
- **THEN** a entrada contém `document_path` apontando para `test_results/{numero_op}/seriais/{serial}`

#### Scenario: Enfileiramento de reprovado
- **WHEN** um teste reprovado é enfileirado para sync
- **THEN** a entrada contém `document_path` apontando para `test_results/{numero_op}/reprovadas/{sequencial}`

#### Scenario: Compatibilidade com fila legada
- **WHEN** uma entrada antiga na fila possui apenas `collection` e `document_id` (sem `document_path`)
- **THEN** o processador continua gravando no formato legado até a entrada ser drenada

### Requirement: Proibição de delete na hierarquia test_results
O app SHALL NOT enfileirar operações de delete em `test_results` ou subcoleções `seriais` e `reprovadas`.

#### Scenario: Tentativa de remoção na nuvem
- **WHEN** o sistema tentaria remover um documento de `test_results/{numero_op}/seriais/{serial}` ou `reprovadas/{sequencial}` da nuvem
- **THEN** nenhuma operação delete é enfileirada
