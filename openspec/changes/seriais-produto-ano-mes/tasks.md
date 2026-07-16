## 1. Paths e helpers

- [x] 1.1 Adicionar `catalogSerialPath(idProduto, yyyy, mm, serial)` em `firestore_mappers.dart`
- [x] 1.2 Helper puro `catalogYearMonthFromTimestamp(DateTime utc)` → `(yyyy, mm)` em `America/Sao_Paulo`
- [x] 1.3 Testes unitários do helper (incluindo limite UTC vs SPT)

## 2. Sync

- [x] 2.1 Em `enqueueTestResult`, após enfileirar path por lote, enfileirar `set` no path de catálogo com o mesmo payload
- [x] 2.2 Garantir que reprovado e reteste aprovado **não** enfileiram catálogo
- [x] 2.3 Estender `sync_queue_test.dart` cobrindo path `seriais/{produto}/anos/.../itens/{serial}`

## 3. Firestore rules

- [x] 3.1 Adicionar match em `firebase/firestore.rules` para `seriais/{productId}/anos/{year}/meses/{month}/itens/{serial}`
- [x] 3.2 Deploy rules da raiz do repo (`firebase deploy --only firestore:rules`)

## 4. Verificação

- [x] 4.1 `flutter test` nos testes de sync/mappers afetados
- [ ] 4.2 Smoke: com sync ativo, aprovar uma peça e confirmar documento sob lote **e** sob `seriais/{produto}/anos/{YYYY}/meses/{MM}/itens/{serial}` no Console
