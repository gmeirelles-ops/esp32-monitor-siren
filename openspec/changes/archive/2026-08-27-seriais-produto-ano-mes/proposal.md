## Why

Seriais aprovados hoje só aparecem sob o lote (`test_results/{numero_op}/seriais/{serial}`), o que dificulta navegar no Console por produto e período. Precisamos de uma árvore `seriais/{produto}/{ano}/{mes}` indexada pelo dia do teste, sem abandonar a hierarquia por OP.

## What Changes

- Espelhar cada serial ITF **aprovado** também em `seriais/{id_produto}/{ano}/{mes}/{serial}` no Firestore
- `{mes}` e `{ano}` derivados do **timestamp do teste** (dia em que foi testado), não do contador local
- **Manter** a escrita existente em `test_results/{numero_op}/seriais/{serial}` (dupla gravação na sync)
- Atualizar rules Firestore e índices se necessário para create/read nessa árvore
- Não migrate/backfill histórico obrigatório na v1 (opcional posterior)

## Capabilities

### New Capabilities

- `seriais-catalog-hierarchy`: Catálogo Firestore de seriais aprovados por produto → ano → mês → serial ITF

### Modified Capabilities

- `firestore-lote-serial-schema`: Sync de aprovação passa a enfileirar também o path do catálogo temporal (além do path por lote)
- `firestore-sync`: Fila de sync grava documento espelho com o mesmo payload do serial aprovado

## Impact

- `sirene_app` sync (`firestore_sync_service`, `firestore_mappers`, possivelmente processor)
- `firebase/firestore.rules` (match para `seriais/{produto}/...`)
- Console Firebase: navegação por produto/mês
- Consultas por OP / collection group em `test_results/.../seriais` inalteradas
- Contador local `serial_counters` **não** muda (continua só SQLite)
