# Research: Resiliência do fluxo de teste

**Feature**: 003-test-flow-resilience  
**Date**: 2026-07-08

## R1 — Chave de dedupe

**Decision**: `(numero_op, ts_ms)` quando firmware envia `ts_ms`.

**Rationale**: Campo já existe no JSON firmware; evita colisão entre reprovados no mesmo sequencial.

**Alternatives considered**: UUID `event_id` — rejeitado (mudança maior de contrato).

**Fallback legado**: mensagens sem `ts_ms` usam dedupe por `(op, seq, veredito, potencia)` para replays MQTT.

---

## R2 — Firestore reprovadas

**Decision**: Path `test_results/{op}/reprovadas/{ts_ms}`.

**Rationale**: Permite múltiplas reprovações no mesmo sequencial.

**Alternatives**: `{sequencial}_{ts_ms}` — aceito como formato de id quando ts_ms ausente usa sequencial legado.

---

## R3 — Heartbeat imediato

**Decision**: `telemetry_publish_now()` ao entrar `STATE_TESTING` e após `publish_test_result`.

**Rationale**: Heartbeat periódico é 30s; testes duram 10–15s.

---

## R4 — Ordem de persistência no app

**Decision**: `insertTestResult` → `state=` → etiqueta/sync assíncronos.

**Rationale**: UI não deve esperar impressora Zebra.

---

## R5 — Compatibilidade

**Decision**: App aceita testes sem `ts_ms` (firmware antigo); dedupe legado mais restritivo.
