## 1. Banco de dados

- [x] 1.1 Adicionar coluna `operador` (nullable) em `TestResults`
- [x] 1.2 Migração schema v4 → v5 com `addColumn`
- [x] 1.3 `insertTestResult` aceita `operador`
- [x] 1.4 Regenerar `database.g.dart`

## 2. Sincronização e captura

- [x] 2.1 `mapTestResult` inclui `operador` quando presente
- [x] 2.2 `enqueueTestResult` recebe e repassa `operador`
- [x] 2.3 `mqtt_providers` lê o e-mail do operador autenticado e repassa a insert/enqueue

## 3. UI

- [x] 3.1 Exibir operador no card de último resultado na tela de Lote

## 4. Validação

- [x] 4.1 Teste unitário: `mapTestResult` inclui/omite `operador`
- [x] 4.2 `flutter analyze` e `flutter test` passando
