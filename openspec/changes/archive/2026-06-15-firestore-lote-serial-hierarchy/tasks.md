## 1. Schema e mappers

- [x] 1.1 Definir helpers de caminho Firestore em `firestore_mappers.dart` (`lotePath`, `serialPath`, `reprovadaPath`)
- [x] 1.2 Implementar `mapLoteDocument`, `mapSerialDocument`, `mapReprovadaDocument` com campos acordados no design
- [x] 1.3 Atualizar testes em `firestore_mappers_test.dart`

## 2. Fila de sync (SQLite + processor)

- [x] 2.1 Migration Drift: coluna `document_path` nullable em `SyncQueue`
- [x] 2.2 Estender `enqueueSync` para aceitar `documentPath` opcional
- [x] 2.3 Atualizar `SyncQueueProcessor` / `writeToFirestore` para resolver `document_path` completo
- [x] 2.4 Atualizar `sync_queue_test.dart` com caminhos `seriais/` e `reprovadas/`

## 3. FirestoreSyncService

- [x] 3.1 `enqueueTestResult`: aprovado → lote + `seriais/{serial}`; reprovado → lote + `reprovadas/{sequencial}`; reteste aprovado → só lote
- [x] 3.2 `enqueueBatchStart` / `enqueueBatchEnd`: escrever em `test_results/{numero_op}`; remover writes em `batches/`
- [x] 3.3 Garantir ordem FIFO correta (lote antes de subcoleção)

## 4. Firebase infra

- [x] 4.1 Atualizar `firebase/firestore.rules` para `test_results/{numeroOp}/{sub=**}`
- [x] 4.2 Adicionar índices collection group em `firebase/firestore.indexes.json`
- [x] 4.3 Validar deploy local ou dry-run (`firebase deploy --only firestore:rules,firestore:indexes`)

## 5. Migração e documentação

- [x] 5.1 Script opcional `scripts/migrate_firestore_lote_serial.js` (flat → seriais/reprovadas)
- [x] 5.2 Atualizar `sirene-validator/docs/GUIA_COMPLETO.md` seção Firestore com novo schema
- [x] 5.3 Atualizar `docs/PRODUCAO.md` checklist de sync na nuvem

## 6. Validação

- [ ] 6.1 Teste manual: aprovar sirene → verificar `test_results/{op}/seriais/{serial}` no Console
- [ ] 6.2 Teste manual: reprovação → verificar `test_results/{op}/reprovadas/{sequencial}` sem entrada em `seriais`
- [x] 6.3 `flutter test` passando nos pacotes cloud/sync
