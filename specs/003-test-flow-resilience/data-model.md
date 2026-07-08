# Data Model: Resiliência do fluxo de teste

## TestResult (SQLite)

| Campo | Tipo | Notas |
|-------|------|-------|
| id | int PK | auto |
| deviceId | text | |
| numeroOp | text | |
| veredito | text | APROVADO/REPROVADO |
| potenciaMedia | real | |
| sequencial | int | reutilizado em reprovados |
| firmwareTsMs | int? | **novo** — `ts_ms` do firmware |
| aprovadosNoLote | int | |
| serial | text? | |
| createdAt | datetime | |

**Índice**: `(numero_op, firmware_ts_ms)` WHERE firmware_ts_ms IS NOT NULL

## TestResultMessage (MQTT)

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| tsMs | int? | recomendado |
| tsUnix | int? | opcional |
| numeroOp | string | sim |
| sequencial | int | sim |
| veredito | string | sim |

## Dedupe

- Com `tsMs`: `(numeroOp, tsMs)`
- Sem `tsMs`: `(numeroOp, sequencial, veredito, potenciaMedia)` para replay

## Firestore

- Aprovados: `test_results/{op}/seriais/{serial}` (inalterado)
- Reprovados: `test_results/{op}/reprovadas/{ts_ms}`
