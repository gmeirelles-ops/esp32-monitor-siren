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
./scripts/ci_local.sh — executado durante implementação
flutter test mqtt_* + batch_set_batch_contract — PASS
```

## Observações

- Validação física deve ser executada pelo operador no posto seguindo [quickstart.md](./quickstart.md).
- Após deploy do app corrigido, repetir Fases A–E e atualizar esta tabela.

## Veredicto

**E2E físico: PENDENTE** — aguardando execução na bancada com app atualizado.

**E2E automatizado (CI + parsers): PASS**
