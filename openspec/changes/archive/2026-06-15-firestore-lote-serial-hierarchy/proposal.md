## Why

Hoje o Firestore grava resultados de teste como documentos planos em `test_results/{numero_op}_{sequencial}`, separados de `batches/{numero_op}`. Isso dificulta consultar “todos os seriais de um lote” no Console e em dashboards externos — é preciso filtrar por `numero_op` em uma coleção flat. A hierarquia **lote → seriais** reflete o modelo mental da produção (OP contém sirenes aprovadas) e simplifica leitura na nuvem.

## What Changes

- **BREAKING:** substituir `test_results/{numero_op}_{sequencial}` por estrutura aninhada:
  - `test_results/{numero_op}` — documento do **lote** (metadados de OP)
  - `test_results/{numero_op}/seriais/{serial}` — um documento por **número de série** aprovado
  - `test_results/{numero_op}/reprovadas/{sequencial}` — um documento por **teste reprovado** (sem serial)
- Consolidar metadados de lote de `batches/{numero_op}` no documento `test_results/{numero_op}`; **deixar de escrever** em `batches/` (coleção legada mantida read-only para dados antigos).
- Estender fila `SyncQueue` e `SyncQueueProcessor` para suportar caminhos com subcoleções.
- Atualizar `firestore.rules`, índices e documentação (`GUIA_COMPLETO.md`, `PRODUCAO.md`).
- Script opcional de migração one-shot para documentos flat existentes (não bloqueia deploy do app).

## Capabilities

### New Capabilities

- `firestore-lote-serial-schema`: esquema hierárquico Firestore (lote, seriais, reprovadas) e contrato de campos.

### Modified Capabilities

- `firestore-sync`: caminhos de escrita, idempotência e enfileiramento na nova hierarquia.
- `firebase-setup`: regras e índices Firestore para subcoleções em `test_results`.

## Impact

- `sirene_app/lib/features/cloud/sync/` — `FirestoreSyncService`, `SyncQueueProcessor`, mappers
- `sirene_app/lib/core/database/database.dart` — schema `SyncQueue` (campo `document_path` ou equivalente)
- `firebase/firestore.rules`, `firebase/firestore.indexes.json`
- Testes: `firestore_mappers_test.dart`, `sync_queue_test.dart`
- Consumidores externos do Firestore (dashboards, scripts) devem migrar queries de flat para subcoleções
- SQLite local **inalterado** — source of truth continua local; só muda espelhamento na nuvem
