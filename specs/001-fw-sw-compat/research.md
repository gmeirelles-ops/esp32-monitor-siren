# Incidente: testes múltiplos e aprovação falha — OP 0001 / produto 072

**Data**: 2026-07-07  
**SET_BATCH reportado**:
```json
{"cmd":"SET_BATCH","numero_op":"0001","id_produto":"072","ano":"26","tempo_teste":10,"potencia_min":35.62,"potencia_max":43.54,"quantidade_total":108,"proximo_sequencial":500,"modo_reteste":false}
```

**Sintomas**:
- Aprovou somente 1 produto; demais testes sem aprovar nem reprovar na UI
- 1 toque no botão → 3–4 testes registrados

---

## R11 — Causas prováveis (ordenadas por likelihood)

### C1 — Fila offline do firmware republica testes antigos (ALTA)

**Decision**: Cada `app_publish_or_queue("status", ...)` enfileira se MQTT cair. Ao reconectar, `drain_queue()` publica **todos** os JSONs acumulados em burst.

**Rationale**: Explica testes **sem novo toque** no botão. App processava cada mensagem como teste novo.

**Mitigação app**: dedupe por `(numero_op, ts_ms)` em `processTestResult` (feature 003); fallback legado `(numero_op, sequencial)` para payloads sem `ts_ms`.

**Mitigação firmware (003)**: `telemetry_publish_now()` ao iniciar/terminar teste; replay deduplicado no app por `ts_ms`.

**Status**: Mitigado em app (003-test-flow-resilience, 2026-07-08).

---

### C2 — Parser MQTT gerava múltiplos eventos de 1 payload (MÉDIA)

**Decision**: `tryParseJsonObjects` recuperava **um objeto por tipo** (teste + batch + rejeição) do mesmo payload colado.

**Rationale**: Podia disparar `processTestResult` + `clearActiveBatch` no mesmo handler, dessincronizando lote.

**Mitigação**: recovery retorna **apenas o primeiro** objeto por prioridade (`teste` > `rejeicao` > `batch`).

---

### C3 — Teste com veredito inválido/vazio (MÉDIA)

**Decision**: JSON colado às vezes chegava sem `veredito` parseável → app gravava teste “fantasma”.

**Mitigação**: `parseTestResult` exige `veredito` ∈ {`APROVADO`,`REPROVADO`} e `sequencial > 0`.

---

### C4 — Serial duplicado silencioso (MÉDIA)

**Decision**: Segunda aprovação com mesmo sequencial → `serialExists` bloqueia etiqueta mas **UI não avisava**.

**Mitigação**: snackbar em `duplicateSerialProvider` no painel ao vivo.

---

### C5 — Botão / fila PZEM no firmware (BAIXA para este caso)

**Decision**: Fila de botão (4 eventos) + worker loop pode enfileirar múltiplos `PZEM_WORK_TEST` se vários eventos ficarem na fila **entre** testes.

**Rationale**: Menos provável com debounce 50 ms e `s_test_in_progress`, mas possível com ruído GPIO.

**Alternatives**: Flush da fila de botão ao iniciar teste (mudança firmware).

---

## SET_BATCH específico — validação

| Campo | Valor | Firmware OK? |
|-------|-------|--------------|
| potencia_min/max | 35.62 / 43.54 | ✅ inclusive |
| tempo_teste | 10 | ✅ 1–120 s |
| proximo_sequencial | 500 | ✅ ≥ 1 |
| quantidade_total | 108 | ✅ |

Payload **válido** — problema não é rejeição de SET_BATCH por campos.

---

## Correções aplicadas (software only)

1. Dedupe `(numero_op, sequencial)` antes de `processTestResult`
2. Parser recovery = 1 evento por payload
3. Validação estrita de veredito/sequencial
4. UI avisa serial duplicado

**Firmware**: sem alteração nesta correção.

---

## Validação recomendada na bancada

1. Verificar heartbeat `fila` — se > 0 antes do teste, fila offline pendente
2. Após 1 toque, conferir **um** incremento de `sequencial` no MQTT
3. Confirmar no app: 1 linha no painel por teste, veredito APROVADO ou REPROVADO
4. Se repetir: capturar payload bruto em `/status` via MQTT Explorer
