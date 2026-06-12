## MODIFIED Requirements

### Requirement: Fila local de sincronização
O app SHALL enfileirar operações de escrita Firestore em tabela SQLite (`SyncQueue`) antes de tentar envio, garantindo durabilidade mesmo com falha de rede.

#### Scenario: Evento enfileirado offline
- **WHEN** um resultado de teste é gravado no SQLite e não há conectividade
- **THEN** uma entrada é criada na `SyncQueue` com collection, document_id, payload JSON e timestamp

#### Scenario: Fila drenada ao reconectar
- **WHEN** a rede retorna e o operador está autenticado com sync habilitado
- **THEN** o processador da fila envia pendências em ordem FIFO, removendo entradas bem-sucedidas

#### Scenario: Falha permanente após retries
- **WHEN** uma entrada da fila falha após 5 tentativas com backoff
- **THEN** a entrada permanece marcada com `last_error` e o app exibe contagem de falhas nas Configurações

## ADDED Requirements

### Requirement: Recuperação manual de dead-letter da fila
O app SHALL listar entradas da `SyncQueue` com falha permanente (`attempts >= 5`), exibir `last_error` e permitir ao operador reiniciar o processamento resetando tentativas e reenfileirando o envio.

#### Scenario: Listagem de falhas permanentes
- **WHEN** existem entradas com `attempts >= 5` e o operador abre Configurações com sync habilitado
- **THEN** o app lista cada entrada com collection, document_id, instante e último erro

#### Scenario: Retry manual de dead-letter
- **WHEN** o operador aciona "Tentar novamente" em uma falha permanente ou em todas
- **THEN** o app zera `attempts` e `last_error` das entradas selecionadas e dispara o processador da fila

#### Scenario: Retry bem-sucedido
- **WHEN** após retry manual a rede e autenticação estão OK
- **THEN** a entrada é enviada ao Firestore e removida da fila local
