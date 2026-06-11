## 1. Banco de dados

- [x] 1.1 Adicionar tabela `SerialCounters` (idProduto, ano, lastSequencial, updatedAt) no Drift
- [x] 1.2 Migração schema v3 → v4 com criação da tabela e backfill a partir de `test_results` aprovados
- [x] 1.3 Métodos: `getLastSequencial`, `bumpSerialCounter`, `serialExists`, `nextSequencialFor`
- [x] 1.4 Método `reconcileSerials(idProduto, ano)` retornando gaps e duplicatas
- [x] 1.5 Regenerar `database.g.dart` (build_runner)

## 2. Geração de serial com trava anti-duplicado

- [x] 2.1 Em `mqtt_providers._handleMessage`, checar `serialExists` antes de bufferizar
- [x] 2.2 Em serial inédito: bufferizar + `bumpSerialCounter`
- [x] 2.3 Em serial duplicado: não bufferizar e emitir alerta (provider/snackbar)

## 3. Formulário de lote

- [x] 3.1 Pré-preencher `proximo_sequencial` ao escolher produto ou alterar ano
- [x] 3.2 Exibir texto de ajuda com o último sequencial conhecido
- [x] 3.3 Painel de reconciliação (gaps/duplicatas) para o produto/ano selecionado

## 4. Testes e validação

- [x] 4.1 Teste unitário: `bumpSerialCounter` usa max e é idempotente
- [x] 4.2 Teste unitário: `nextSequencialFor` (com e sem histórico)
- [x] 4.3 Teste unitário: `reconcileSerials` detecta gaps e duplicatas
- [x] 4.4 `flutter analyze` e `flutter test` passando
