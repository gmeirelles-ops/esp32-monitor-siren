## ADDED Requirements

### Requirement: Regras Firestore para hierarquia test_results
O arquivo `firebase/firestore.rules` SHALL permitir leitura e escrita autenticada em `test_results/{numeroOp}` e em todas as subcoleções descendentes (`seriais`, `reprovadas`). Writes em subcoleções SHALL exigir `station_id` não vazio no payload.

#### Scenario: Write de serial autenticado
- **WHEN** um usuário autenticado grava `test_results/2026001/seriais/1232600018` com `station_id` válido
- **THEN** a operação é permitida

#### Scenario: Write sem station_id
- **WHEN** um write em `test_results/{numeroOp}/reprovadas/{sequencial}` não contém `station_id`
- **THEN** a operação é rejeitada

#### Scenario: Delete bloqueado
- **WHEN** um usuário autenticado tenta `delete` em `test_results/{numeroOp}/seriais/{serial}`
- **THEN** a operação é rejeitada

### Requirement: Índices Firestore para subcoleções
O arquivo `firebase/firestore.indexes.json` SHALL incluir índice collection group para subcoleção `seriais` quando necessário para consultas cross-lote por serial ou `station_id`.

#### Scenario: Deploy de índices
- **WHEN** o administrador executa `firebase deploy --only firestore:indexes`
- **THEN** índices para `seriais` (collection group) são criados sem erro

## MODIFIED Requirements

### Requirement: Arquivos de configuração Firebase versionados
O repositório SHALL conter `firebase.json`, `firebase/firestore.rules` e `firebase/firestore.indexes.json` na raiz do monorepo, permitindo deploy reproduzível das regras e índices incluindo a hierarquia `test_results/{lote}/seriais/{serial}`.

#### Scenario: Deploy de regras
- **WHEN** o administrador executa `firebase deploy --only firestore` na raiz do repositório
- **THEN** as security rules e índices (incluindo subcoleções de `test_results`) são aplicados ao projeto Firebase configurado
