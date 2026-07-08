# Bench Results: Validação física E2E

**Feature**: 002-e2e-health-audit  
**Date**: 2026-07-07  
**Executor**: _pendente — execução manual na bancada_  
**Ambiente**: _preencher (broker, bancada NN, app versão)_

## SET_BATCH usado

```json
{"cmd":"SET_BATCH","numero_op":"0001","id_produto":"072","ano":"26","tempo_teste":10,"potencia_min":35.62,"potencia_max":43.54,"quantidade_total":108,"proximo_sequencial":500,"modo_reteste":false}
```

## Resultados por fase

| Fase | Item | Resultado | Notas |
|------|------|-----------|-------|
| A | Pré-requisitos | PENDENTE | Requer bancada física |
| B | MQTT + lote | PENDENTE | |
| C | Teste físico (1 toque = 1 teste) | PENDENTE | |
| D | Serial + marcação | PENDENTE | |
| E | Firestore sync | PENDENTE | |
| F | CI local | PASS | Automatizado em 2026-07-07 |

## CI local (automático)

```
flutter test mqtt_parser_test mqtt_status_parser_test batch_set_batch_contract_test — 21/21 PASS (2026-07-07)
ci_local.sh — não executado nesta sessão (requer ambiente Linux/WSL para host_tests)
```

## Observações

- Validação física deve ser executada pelo operador no posto seguindo [quickstart.md](./quickstart.md).
- Após deploy do app corrigido, repetir Fases A–E e atualizar esta tabela.

## 003-test-flow-resilience (rede lenta / dedupe ts_ms)

**Date**: 2026-07-08  
**Executor**: _pendente — cenários em [../003-test-flow-resilience/quickstart.md](../003-test-flow-resilience/quickstart.md)_

| Cenário | Resultado | Notas |
|---------|-----------|-------|
| 3 reprovados mesmo seq (rede lenta) | PENDENTE | App: dedupe por `ts_ms` — `flutter test test_dedupe_ts_ms_test.dart` PASS |
| Fila offline + reconexão | PENDENTE | |
| Aprovação antes da etiqueta | PENDENTE | Insert SQLite antes de impressão implementado |


## Instruções para operador (executar no posto)

Siga [quickstart.md](./quickstart.md) fases A–E com estes parâmetros:

| Parâmetro | Valor |
|-----------|-------|
| OP | 0001 |
| Produto | 072 |
| Limites | 35.62–43.54 W |
| Sequencial inicial | 500 |
| Quantidade | 108 |
| Tempo teste | 10 s |

**Critério crítico (incidente OP 0001):** 1 toque no botão = exatamente 1 teste na UI; veredito sempre APROVADO ou REPROVADO.

Após executar, marque OK? nas fases A–E acima e atualize o veredicto.

---

## Veredicto

**E2E físico: PENDENTE** — aguardando execução na bancada com app atualizado.

**E2E automatizado (CI + parsers): PASS**
