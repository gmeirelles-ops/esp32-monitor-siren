# Research: Auditoria ponta a ponta — Diponto Sirene

**Feature**: 002-e2e-health-audit  
**Date**: 2026-07-07

## R1 — Arquitetura E2E

**Decision**: Fluxo produção = ESP32 (teste físico) → MQTT → sirene_app (serial/sync) → Firestore opcional.

**Rationale**: Firmware não fala com Firebase; app é ponte offline-first.

**Componentes críticos**:
- Firmware: `sirene-validator/` v1.7.5
- App: `sirene_app/` Windows
- Cloud: `firebase/` + `firestore_sync_service.dart`

---

## R2 — Tópicos MQTT (atual)

**Decision**: `{site}/bancada-{NN}/{suffix}` (padrão `producao/bancada-03/...`).

**Alternatives considered**: `sirene/<device_id>/` — legado, removido do código.

---

## R3 — CI vs E2E físico

**Decision**: CI cobre lógica pura + parsers; E2E físico é gate manual.

| Automatizado | Manual |
|--------------|--------|
| flutter test | Botão + PZEM real |
| host_tests | Etiqueta/laser |
| ci_local.sh | Firestore live sync |

---

## R4 — Incidente OP 0001 (herdado de 001)

**Decision**: Causas: fila offline firmware + parser multi-evento + serial duplicado silencioso.

**Mitigação app**: dedupe, veredito estrito, UI duplicate serial — implementado em `mqtt_parser.dart`, `mqtt_providers.dart`.

**Firmware**: sem mudança necessária para mitigação imediata.

---

## R5 — Documentação desatualizada (pré-correção)

**Decision**: PRODUCAO.md (v1.3.0), e2e_verificacao_completa.sh (tópicos legados), README diagrama — corrigidos nesta feature.

---

## R6 — Firestore schema

**Decision**: Hierarquia lote-serial:
- `test_results/{numero_op}` (documento lote)
- `test_results/{numero_op}/seriais/{serial}` (aprovados)
- `test_results/{numero_op}/reprovadas/{sequencial}` (reprovados)

**Nota**: Script E2E antigo usava `test_results/{op}_{seq}` flat — incorreto.

---

## R7 — Validação física

**Decision**: Checklist em `quickstart.md` + registro em `bench-results.md`.

**Status**: Pendente execução na bancada (requer operador + hardware).

---

## Resumo de prontidão

| Item | Pronto? |
|------|---------|
| Contrato MQTT | Sim |
| App parser/dedupe | Sim (deploy pendente) |
| CI local | Sim |
| Docs/scripts | Sim (após implement) |
| Bench físico | Não validado |
