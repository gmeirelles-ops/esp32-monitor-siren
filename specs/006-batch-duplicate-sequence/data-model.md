# Data Model: 006-batch-duplicate-sequence

## BatchSession (app in-memory + firmware NVS)

| Campo | Tipo | Notas |
|-------|------|-------|
| numeroOp | string | OP do lote |
| proximoSequencial | int | Espelho do firmware; fonte = heartbeat |
| aprovados | int | Contador ao vivo |
| batchStartedAt | datetime | Filtro de sessão no app |
| modoReteste | bool | Não conta na meta |

## LiveCounters (painel operador)

| Campo | Tipo | Fonte |
|-------|------|-------|
| aprovados | int | heartbeat.aprovados reconciliado |
| reprovados | int | SQLite sessão |
| proximoSequencialEsperado | int | heartbeat.proximo_sequencial |
| estado | enum | online / offline / testing / batchReady |
| filaOffline | int | heartbeat.fila |

## TestCycle

| Campo | Tipo | Notas |
|-------|------|-------|
| numeroOp | string | |
| tsMs | int | **Chave dedupe** com numeroOp |
| sequencial | int | Não incrementa em reprovado |
| veredito | string | APROVADO / REPROVADO |
| potenciaMedia | float | |

**Identidade**: `(numeroOp, tsMs)` — um resultado físico por timestamp.

## PostApprovalLock (firmware)

| Campo | Tipo | Notas |
|-------|------|-------|
| ultimoVeredito | string | De app_last_test |
| ultimoTsMs | int64 | Momento do último teste |
| cooldownMs | int | Default 5000 |

## State transitions

```text
BATCH_READY + botão (após APROVADO < 5s) → rejeição peca_ja_aprovada
BATCH_READY + botão (após REPROVADO) → TESTING (mesmo sequencial)
SET_BATCH → aprovados=0, proximo_sequencial=payload, ultimo_veredito limpo
MQTT reconnect → reconciliar contadores + seriais pendentes
```
