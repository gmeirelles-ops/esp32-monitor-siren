# Implementation Plan: 003-test-flow-resilience

**Branch**: `003-test-flow-resilience`  
**Spec**: [spec.md](./spec.md)

## Summary

Eliminar "pular sirene" com dedupe `(numero_op, ts_ms)`, insert SQLite antes de etiqueta, heartbeat imediato no firmware, e estados UI Testando/Aguardando MQTT.

## Phases

### Phase 0 — Research ✓

[research.md](./research.md): `ts_ms` como chave de dedupe; Firestore reprovadas por `ts_ms`; heartbeat imediato em transições.

### Phase 1 — Design ✓

- [data-model.md](./data-model.md)
- [contracts/mqtt-test-events.md](./contracts/mqtt-test-events.md)

### Phase 2 — Implementation ✓

| Grupo | Entregas |
|-------|----------|
| App A1–A5 | Parser `ts_ms`, migration v19, dedupe, insert antes etiqueta, Firestore path |
| App A4 | `awaitingMqttResult`, hero Aguardando MQTT, strip fila |
| Firmware B1 | `telemetry_publish_now()` em TESTING e pós-teste |
| Testes | `test_dedupe_ts_ms_test.dart`, parser, mappers |
| Docs C1–C3 | openspec batch-test-execution, bench-results, fw-sw-compat research |

### Phase 3 — Validação

[quickstart.md](./quickstart.md) — bancada com rede lenta simulada (pendente execução física).

## Constitution

- Testes automatizados (`flutter test`)
- Contrato mínimo (reusar `ts_ms` existente)
- Bench físico documentado em bench-results
