## 1. Lógica de sequencial

- [x] 1.1 Criar helper `nextBatchSequencial(batch, aprovadosNoLote)` em módulo compartilhado (ex. `batch_serial_logic.dart`)
- [x] 1.2 Em `processTestResult`, após serial emitido, atualizar `activeBatch.proximoSequencial = test.sequencial + 1`
- [x] 1.3 Corrigir `simulateTestResult` para usar sequencial incremental (`proximoSequencial + metrics.aprovados` em aprovação)

## 2. Testes

- [x] 2.1 Teste unitário: 4 aprovações simuladas → 4 seriais distintos no buffer (seq 1..4)
- [x] 2.2 Teste unitário: reprovação entre aprovações não pula sequencial de aprovação
- [x] 2.3 Teste: `activeBatch.proximoSequencial` avança após cada emissão

## 3. UI

- [x] 3.1 Batch Live Dashboard: seção "Seriais emitidos" listando seriais da OP (test_results + buffer)
- [x] 3.2 Etiquetas: confirmar lista mostra todos os itens do buffer (sem regressão)

## 4. Validação

- [x] 4.1 Rodar `flutter test` e validar fluxo manual: 4× Simular teste → 4 etiquetas pendentes com seriais diferentes
