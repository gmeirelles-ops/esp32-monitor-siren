## MODIFIED Requirements

### Requirement: Sincronização idempotente de resultados de teste
O app SHALL gravar em `test_results/{numero_op}_{sequencial}` com merge/set, usando chave composta que impede duplicatas em reprocessamento.

#### Scenario: Teste aprovado sincronizado
- **WHEN** o app recebe MQTT `tipo: "teste"` e grava no SQLite
- **THEN** o sync service enfileira documento com `device_id`, `numero_op`, `veredito`, `potencia_media`, `sequencial`, `serial` (se aprovado), `operador` (se autenticado), `timestamp` e `station_id`

#### Scenario: Reprocessamento do mesmo teste
- **WHEN** a mesma combinação `numero_op` + `sequencial` é enfileirada novamente
- **THEN** o Firestore recebe upsert no mesmo document ID sem criar registro duplicado
