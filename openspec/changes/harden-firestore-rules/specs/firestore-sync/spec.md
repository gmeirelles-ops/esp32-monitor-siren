## MODIFIED Requirements

### Requirement: Fila local de sincronização
O app SHALL enfileirar operações de escrita Firestore em tabela SQLite (`SyncQueue`) antes de tentar envio, garantindo durabilidade mesmo com falha de rede. O app SHALL NOT enfileirar operações de delete em `test_results`.

#### Scenario: Evento enfileirado offline
- **WHEN** um resultado de teste é gravado no SQLite e não há conectividade
- **THEN** uma entrada é criada na `SyncQueue` com collection, document_id, payload JSON e timestamp

#### Scenario: Fila drenada ao reconectar
- **WHEN** a rede retorna e o operador está autenticado com sync habilitado
- **THEN** o processador da fila envia pendências em ordem FIFO, removendo entradas bem-sucedidas

#### Scenario: Falha permanente após retries
- **WHEN** uma entrada da fila falha após 5 tentativas com backoff
- **THEN** a entrada permanece marcada com `last_error` e o app exibe contagem de falhas nas Configurações

#### Scenario: Delete de test_result não enfileirado
- **WHEN** o sistema tentaria remover um documento de `test_results` da nuvem
- **THEN** nenhuma entrada de delete é criada na `SyncQueue`
