---
description: "Task list — auditoria ponta a ponta E2E (002-e2e-health-audit)"
---

# Tasks: Auditoria ponta a ponta — Diponto Sirene

**Input**: Design documents from `/specs/002-e2e-health-audit/`

**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Organization**: Tarefas agrupadas por user story para entrega incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo
- **[Story]**: User story do spec.md (US1–US5)

## Path Conventions

- **Firmware**: `sirene-validator/`
- **App Flutter**: `sirene_app/lib/` e `sirene_app/test/`
- **Docs**: `docs/`, `scripts/`, `specs/002-e2e-health-audit/`

---

## Phase 1: Setup (Artefatos Speckit)

**Purpose**: Gerar documentação da feature 002

- [X] T001 Criar `specs/002-e2e-health-audit/spec.md` e checklist requirements
- [X] T002 [P] Criar `plan.md`, `research.md`, `quickstart.md` em `specs/002-e2e-health-audit/`
- [X] T003 Atualizar `.specify/feature.json` → `specs/002-e2e-health-audit`
- [X] T004 Criar `bench-results.md` template para validação física

---

## Phase 2: User Story 5 — Documentação e scripts alinhados (Priority: P3, executado cedo)

**Goal**: PRODUCAO.md, README e e2e script refletem contrato atual (1.7.5, `producao/bancada-NN/`)

**Independent Test**: `grep -r "1.3.0" docs/PRODUCAO.md` vazio; e2e script usa tópicos bancada

### Implementation for User Story 5

- [X] T005 [US5] Atualizar `docs/PRODUCAO.md` firmware 1.3.0 → 1.7.5
- [X] T006 [P] [US5] Atualizar `scripts/e2e_verificacao_completa.sh` tópicos `{site}/bancada-NN/` e firmware 1.7.5
- [X] T007 [P] [US5] Atualizar diagrama MQTT em `README.md`

**Checkpoint**: Docs/scripts alinhados ao contrato MQTT atual

---

## Phase 3: User Story 1 — Linha de teste física confiável (Priority: P1)

**Goal**: 1 toque = 1 teste; veredito sempre APROVADO/REPROVADO; dedupe fila offline

**Independent Test**: `flutter test test/mqtt_parser_test.dart test/mqtt_status_parser_test.dart`

### Implementation for User Story 1

- [X] T008 [US1] Correções parser/dedupe em `mqtt_parser.dart`, `mqtt_providers.dart` (herdado 001)
- [ ] T009 [US1] Commit correções MQTT app no repositório
- [ ] T010 [US1] Deploy app no posto Windows (dist — requer confirmação usuário)

---

## Phase 4: User Story 2–4 — Rastreabilidade, marcação, observabilidade (Priority: P1–P2)

**Goal**: Serial + Firestore + rejeições legíveis + firmware version visível

- [X] T011 [US2] Firestore sync schema validado em código (`firestore_sync_service.dart`)
- [X] T012 [P] [US3] Modos etiqueta/laser documentados em PRODUCAO.md
- [X] T013 [P] [US4] Labels rejeição + NVS banner + batch ACK (herdado 001)

---

## Phase 5: Validação automatizada (Priority: P1)

**Purpose**: CI local e testes MQTT

- [ ] T014 Executar `./scripts/ci_local.sh` e registrar em `bench-results.md`
- [ ] T015 [P] Executar `flutter test test/mqtt_* test/batch_set_batch_contract_test.dart`

---

## Phase 6: Validação física bancada (Priority: P1 — manual)

**Goal**: Checklist quickstart §A–E na bancada real (OP 0001, produto 072)

**Independent Test**: 1 toque → 1 teste; serial ITF; Firestore sync

- [ ] T016 [US1] Fase A–B: pré-requisitos + SET_BATCH OP 0001 produto 072
- [ ] T017 [US1] Fase C: 1 toque = 1 teste, veredito claro
- [ ] T018 [US2] [US3] Fase D–E: serial + Firestore
- [ ] T019 Registrar resultados em `bench-results.md`

**Checkpoint**: E2E físico PASS ou gaps documentados

---

## Dependencies & Execution Order

```text
Phase 1 (Setup) → Phase 2 (Docs) → Phase 3 (App commit/deploy)
                                 → Phase 5 (CI)
                                 → Phase 6 (Bench manual)
```

## Parallel Opportunities

- T006 + T007 em paralelo após T005
- T014 + T015 em paralelo
- T016–T18 sequenciais na bancada

## Implementation Strategy

1. Corrigir doc drift (Phase 2)
2. Commit app fixes (Phase 3)
3. CI local (Phase 5)
4. Bench físico no posto (Phase 6 — operador)
