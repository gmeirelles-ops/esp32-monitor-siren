# firestore-sync Specification

## Purpose
Sincronização offline-first entre SQLite local e Firestore: fila durável, idempotência de testes, debounce de dispositivos e espelhamento de lotes e catálogo.
## Requirements
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

### Requirement: Sincronização idempotente de resultados de teste
O app SHALL gravar em `test_results/{numero_op}_{sequencial}` com merge/set, usando chave composta que impede duplicatas em reprocessamento.

#### Scenario: Teste aprovado sincronizado
- **WHEN** o app recebe MQTT `tipo: "teste"` e grava no SQLite
- **THEN** o sync service enfileira documento com `device_id`, `numero_op`, `veredito`, `potencia_media`, `sequencial`, `serial` (se aprovado), `operador` (se autenticado), `timestamp` e `station_id`

#### Scenario: Reprocessamento do mesmo teste
- **WHEN** a mesma combinação `numero_op` + `sequencial` é enfileirada novamente
- **THEN** o Firestore recebe upsert no mesmo document ID sem criar registro duplicado

### Requirement: Sincronização de lotes
O app SHALL criar ou atualizar `batches/{numero_op}` ao configurar ou encerrar lote.

#### Scenario: Lote iniciado
- **WHEN** o operador envia `SET_BATCH` com sucesso
- **THEN** o sync service enfileira batch com `status: "active"`, campos do lote e `started_at`

#### Scenario: Lote encerrado
- **WHEN** o operador envia `END_BATCH`
- **THEN** o sync service atualiza o batch com `status: "completed"` e `ended_at`

### Requirement: Debounce de sincronização de dispositivos
O app SHALL atualizar `devices/{device_id}` no máximo uma vez a cada 60 segundos por dispositivo, para limitar volume de escritas por heartbeat (30 s).

#### Scenario: Heartbeat recebido dentro do intervalo
- **WHEN** chegam dois heartbeats do mesmo `device_id` em menos de 60 segundos
- **THEN** apenas o último estado é enfileirado/enviado após o debounce

#### Scenario: Dispositivo fica offline
- **WHEN** o app recebe LWT `presenca: offline` para um `device_id`
- **THEN** o sync service enfileira atualização imediata com `online: false`, independente do debounce

### Requirement: Upload de catálogo de produtos
O app SHALL enfileirar upsert em `products/{id_produto}` sempre que um produto for criado, editado ou recalibrado localmente.

#### Scenario: Produto cadastrado
- **WHEN** o operador salva um novo produto no SQLite
- **THEN** o sync service enfileira documento com todos os campos do catálogo e `updated_at`

### Requirement: Identificação do posto de trabalho
O app SHALL incluir `station_id` em todos os documentos sincronizados, configurável nas Configurações do app.

#### Scenario: Station ID configurado
- **WHEN** o operador define `station_id` como `posto-02` nas Configurações
- **THEN** novas gravações Firestore incluem `station_id: "posto-02"` ou `updated_by_station: "posto-02"` conforme o schema da coleção

### Requirement: Toggle de sincronização em nuvem
O app SHALL permitir habilitar ou desabilitar a sincronização Firestore nas Configurações, desabilitada por padrão em instalações novas.

#### Scenario: Sync desabilitado
- **WHEN** o toggle de sincronização está desligado
- **THEN** eventos continuam sendo gravados no SQLite mas nenhuma entrada nova é processada para o Firestore

#### Scenario: Sync habilitado após login
- **WHEN** o operador autenticado habilita o toggle
- **THEN** o processador inicia drenagem da fila pendente e passa a enfileirar novos eventos

### Requirement: Indicador de status de sincronização
O app SHALL exibir nas Configurações: estado do sync (ativo/inativo), último sync bem-sucedido e contagem de pendências/falhas na fila.

#### Scenario: Operador consulta status
- **WHEN** o operador abre Configurações com sync habilitado
- **THEN** o app mostra timestamp do último sync e número de itens pendentes na fila

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

