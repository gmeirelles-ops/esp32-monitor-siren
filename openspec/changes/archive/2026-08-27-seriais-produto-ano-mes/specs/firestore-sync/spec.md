## ADDED Requirements

### Requirement: Enfileirar escrita no catálogo seriais por produto/ano/mês
O sync service SHALL, para cada serial aprovado, enfileirar operação `set` no document path do catálogo `seriais/{id_produto}/anos/{YYYY}/meses/{MM}/itens/{serial}` além do path por lote, usando o mesmo payload serial.

#### Scenario: Fila contém path de catálogo
- **WHEN** um teste aprovado com serial é enfileirado com sync habilitado
- **THEN** existe item pendente cuja `document_path` aponta para o catálogo temporal do produto/mês do timestamp do teste

#### Scenario: Idempotência no reprocessamento
- **WHEN** o mesmo item de catálogo é reprocessado pela fila
- **THEN** o documento Firestore é sobrescrito com `set` sem duplicar IDs
