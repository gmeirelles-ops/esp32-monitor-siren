## 1. Pull do catálogo

- [x] 1.1 Mapper reverso puro `productFromFirestore(Map)` (aceita ISO/DateTime, int/double)
- [x] 1.2 `CatalogCloudService` com `CatalogReader` injetável + upsert no SQLite
- [x] 1.3 Provider `catalogCloudServiceProvider` + helper `pullCatalogFromCloud`
- [x] 1.4 Gancho no `setSyncEnabled(true)`: push e depois pull
- [x] 1.5 Botão "Baixar catálogo da nuvem" em Configurações (apenas quando Firebase disponível)

## 2. Reimpressão por serial

- [x] 2.1 Banco: `findTestResultBySerial` e `searchSerials(query, limit)`
- [x] 2.2 UI de busca + botão "Reimprimir" em `labels_screen.dart`
- [x] 2.3 Reimpressão envia `generateZplLabelRow([serial])` sem tocar no buffer

## 3. Testes e validação

- [x] 3.1 Teste unitário: `productFromFirestore` (campos completos, sem id, tipos numéricos)
- [x] 3.2 Teste unitário: `CatalogCloudService` faz upsert via reader fake
- [x] 3.3 Teste unitário: `findTestResultBySerial` / `searchSerials`
- [x] 3.4 `flutter analyze` e `flutter test` passando
