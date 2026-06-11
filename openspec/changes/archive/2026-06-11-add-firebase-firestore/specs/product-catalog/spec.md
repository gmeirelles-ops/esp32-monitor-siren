## ADDED Requirements

### Requirement: Upload do catálogo para Firestore
Quando a sincronização estiver habilitada, o app SHALL enfileirar upsert em `products/{id_produto}` após cada criação, edição ou recalibração de produto no SQLite local.

#### Scenario: Novo produto sincronizado
- **WHEN** o operador conclui cadastro de produto com autocalibração e sync está habilitado
- **THEN** o sync service enfileira documento com `id_produto`, `nome`, limites de potência, tolerância, tempo de teste e metadados de calibração

#### Scenario: Recalibração sincronizada
- **WHEN** o operador recalibra produto existente com sync habilitado
- **THEN** o sync service enfileira atualização com novos limites e `calibrado_em` / `calibrado_device_id` atualizados

### Requirement: Catálogo local independente da nuvem na v1
O app SHALL NOT depender de leitura do Firestore para operação do catálogo local — SQLite permanece fonte de verdade no posto.

#### Scenario: Primeiro uso sem internet
- **WHEN** o operador cadastra produtos com sync desabilitado ou sem conectividade
- **THEN** o catálogo funciona integralmente via SQLite e lotes podem ser configurados normalmente
