# Tasks: 003-test-flow-resilience

## Speckit artifacts

- [x] spec.md
- [x] research.md
- [x] data-model.md
- [x] contracts/mqtt-test-events.md
- [x] plan.md
- [x] tasks.md
- [x] quickstart.md

## Grupo A — App

- [x] A1 Parse `ts_ms` / `ts_unix` em `TestResultMessage` e `mqtt_parser.dart`
- [x] A2 Coluna `firmware_ts_ms`, schema v19, `testExistsByOpAndTsMs()`
- [x] A3 Dedupe `(op, ts_ms)`; insert antes de etiqueta/sync; `awaitingMqttResult`
- [x] A4 UI Testando / Aguardando MQTT no painel operador
- [x] A5 Firestore reprovadas com id `ts_ms`
- [x] A6 Testes dedupe e parser

## Grupo B — Firmware

- [x] B1 `telemetry_publish_now()` ao entrar TESTING e após `publish_test_result`
- [x] B2 `ts_ms` único via `app_now_ts_ms()` (já existente)
- [ ] B3 offline_queue dedupe por `ts_ms` (opcional P2 — não implementado)
- [ ] B4 host_tests dedupe (opcional — coberto por testes Flutter)

## Grupo C — Docs

- [x] C1 Atualizar `openspec/specs/batch-test-execution/spec.md`
- [x] C2 Registrar cenário em `specs/002-e2e-health-audit/bench-results.md`
- [x] C3 Marcar mitigação em `specs/001-fw-sw-compat/research.md`

## Validação física

- [ ] Bench quickstart cenários 1–3 (rede lenta, fila offline, impressora lenta)
