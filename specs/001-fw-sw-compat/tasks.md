---
description: "Task list — compatibilidade firmware × software (001-fw-sw-compat)"
---

# Tasks: Auditoria de Compatibilidade Firmware × Software

**Input**: Design documents from `/specs/001-fw-sw-compat/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Incluídos onde a spec exige recuperação de payload (FR-006) e cobertura de rejeições (SC-003). Não é TDD estrito.

**Organization**: Tarefas agrupadas por user story para entrega incremental e testável.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependência de tarefas incompletas)
- **[Story]**: User story do spec.md (US1, US2, US3)

## Path Conventions

- **Firmware**: `sirene-validator/`
- **App Flutter**: `sirene_app/lib/` e `sirene_app/test/`
- **Docs**: `openspec/specs/`, `specs/001-fw-sw-compat/`

---

## Phase 1: Setup (Baseline)

**Purpose**: Confirmar estado atual e baseline de testes antes das correções

- [X] T001 Verificar branch `001-fw-sw-compat` e artefatos em `specs/001-fw-sw-compat/` (plan.md, research.md, contracts/)
- [X] T002 [P] Executar baseline: `flutter test test/mqtt_parser_test.dart test/mqtt_status_parser_test.dart test/mqtt_topics_test.dart` em `sirene_app/` e registrar resultado

---

## Phase 2: Foundational (Infraestrutura MQTT compartilhada)

**Purpose**: Modelos e parsers base que bloqueiam US1–US3

**⚠️ CRITICAL**: Completar antes das user stories

- [X] T003 Adicionar `BatchEventMessage` (evento `configurado`|`encerrado`, `numero_op`, `motivo`) em `sirene_app/lib/features/mqtt/models/mqtt_messages.dart`
- [X] T004 [P] Adicionar `NvsFaultAlertMessage` ou estender parser de alertas para `tipo:alerta` em `sirene_app/lib/features/mqtt/models/mqtt_messages.dart`
- [X] T005 Estender `MqttStatusParseResult` e `parseMqttStatusPayload` para extrair eventos `tipo:batch` em `sirene_app/lib/features/mqtt/mqtt_status_parser.dart`
- [X] T006 Adicionar providers/streams para batch ACK e alertas NVS em `sirene_app/lib/features/mqtt/mqtt_providers.dart`

**Checkpoint**: Modelos e parsers estendidos — user stories podem iniciar

---

## Phase 3: User Story 1 — Aprovação de produto confiável (Priority: P1) 🎯 MVP

**Goal**: Nenhum teste `APROVADO` no firmware se perde por falha de parse MQTT; serial e registro gerados sempre

**Independent Test**: Publicar payload colado em `/status` com `veredito:APROVADO` → app gera serial ITF e grava em DB (ver `specs/001-fw-sw-compat/quickstart.md` §4 e §8 item 5)

### Implementation for User Story 1

- [X] T007 [US1] Finalizar `sanitizeCorruptedJson`, `_inferAnoFromGluedPrefix` e recuperação em `tryParseJsonObjects` em `sirene_app/lib/features/mqtt/mqtt_parser.dart`
- [X] T008 [US1] Garantir que `parseMqttStatusPayload` em `sirene_app/lib/features/mqtt/mqtt_status_parser.dart` processa objetos recuperados de payload colado
- [X] T009 [P] [US1] Adicionar/validar testes de payload colado em `sirene_app/test/mqtt_parser_test.dart` e `sirene_app/test/mqtt_status_parser_test.dart`
- [X] T010 [US1] Manter log diagnóstico de status não parseado em `sirene_app/lib/features/mqtt/mqtt_providers.dart` (bloco `_handleMessage` para `/status`)
- [X] T011 [US1] Validar que `processTestResult` em `sirene_app/lib/features/mqtt/mqtt_providers.dart` usa `test.sequencial` do firmware para `generateFullSerial` em `sirene_app/lib/features/serial/itf_check_digit.dart`
- [X] T012 [US1] Validar fluxo reteste: aprovação sem serial quando `retestModeProvider` ativo em `sirene_app/lib/features/mqtt/mqtt_providers.dart`

**Checkpoint**: US1 completa — aprovações não se perdem por JSON corrompido

---

## Phase 4: User Story 2 — Configuração de lote alinhada (Priority: P1)

**Goal**: `SET_BATCH` confirmado no firmware com mesmos limites/sequencial; sem regressão de `proximo_sequencial`

**Independent Test**: Iniciar lote no app → inspecionar JSON em `comando` e heartbeat `BATCH_READY`; reenviar mesma OP com sequencial maior → firmware não regride (ver `quickstart.md` §4 passos 2–4)

### Implementation for User Story 2

- [X] T013 [P] [US2] Implementar `MqttParser.parseBatchEvent` para `tipo:batch` em `sirene_app/lib/features/mqtt/mqtt_parser.dart`
- [X] T014 [US2] Atualizar `sendSetBatch` em `sirene_app/lib/features/mqtt/mqtt_providers.dart` para aguardar ACK `batch/configurado` ou `estado:BATCH_READY` no heartbeat (timeout configurável)
- [X] T015 [P] [US2] Adicionar teste de payload `SET_BATCH` vs contrato em `sirene_app/test/mqtt_messages_test.dart` ou novo `sirene_app/test/batch_set_batch_contract_test.dart`
- [X] T016 [US2] Documentar/validar regra `max(atual, payload)` para `proximo_sequencial` em `sirene_app/lib/features/batch/batch_serial_logic.dart` alinhada a `sirene-validator/main/batch_cmd.c`
- [X] T017 [US2] Garantir que `batch_screen.dart` envia `potencia_min`/`potencia_max` com 2 decimais do produto via `sirene_app/lib/features/products/power_limits.dart`

**Checkpoint**: US2 completa — lote configurado com confirmação explícita

---

## Phase 5: User Story 3 — Diagnóstico de falhas visível (Priority: P2)

**Goal**: Operador vê rejeições e alertas NVS/hardware sem falha silenciosa

**Independent Test**: Simular `rejeicao` com `lote_cheio` e alerta `batch_nvs_fault` → banner visível na tela de lote (ver `spec.md` acceptance scenarios US3)

### Implementation for User Story 3

- [X] T018 [P] [US3] Implementar `parseNvsFaultAlert` para `tipo:alerta,evento:batch_nvs_fault` em `sirene_app/lib/features/mqtt/mqtt_parser.dart`
- [X] T019 [US3] Rotear alerta NVS em `_handleMessage` para `/alerta` e expor via provider em `sirene_app/lib/features/mqtt/mqtt_providers.dart`
- [X] T020 [US3] Exibir banner de alerta NVS em `sirene_app/lib/features/batch/batch_live_screen.dart` (padrão `_RejectionBanner` existente)
- [X] T021 [P] [US3] Criar mapa de labels PT para códigos `motivo` firmware em `sirene_app/lib/features/mqtt/models/mqtt_messages.dart` ou `sirene_app/lib/shared/widgets/rejection_labels.dart`
- [X] T022 [US3] Usar labels legíveis em `sirene_app/lib/features/batch/batch_live_screen.dart` e `sirene_app/lib/features/devices/device_detail_screen.dart` para `lastRejection.motivo`
- [X] T023 [P] [US3] Adicionar testes para `lote_cheio` e `batch_nvs_fault` em `sirene_app/test/mqtt_status_parser_test.dart` e `sirene_app/test/mqtt_parser_test.dart`

**Checkpoint**: US3 completa — falhas visíveis ao operador

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentação, validação E2E e alinhamento OpenSpec

- [X] T024 [P] Atualizar tópicos de `sirene/<device_id>/` para `{site}/bancada-NN/` em `openspec/specs/mqtt-messaging/spec.md`
- [X] T025 [P] Atualizar exemplos de tópicos em `scripts/E2E_MQTT_EXPLORER.md`
- [X] T026 Executar checklist E2E de `specs/001-fw-sw-compat/quickstart.md` em bancada real e registrar resultados em `specs/001-fw-sw-compat/research.md` (automatizado OK; físico pendente)
- [X] T027 [P] Atualizar matriz de gaps em `specs/001-fw-sw-compat/plan.md` marcando itens G1–G5 resolvidos

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Phase 1 — **bloqueia** US1, US2, US3
- **US1 (Phase 3)**: Depende de Phase 2 — **MVP** (P0 produção)
- **US2 (Phase 4)**: Depende de Phase 2 (T003–T006); pode paralelizar com US1 após foundational
- **US3 (Phase 5)**: Depende de Phase 2 (T004, T006); pode paralelizar com US1/US2
- **Polish (Phase 6)**: Depende das user stories desejadas

### User Story Dependencies

| Story | Depende de | Independente de |
|-------|-----------|-----------------|
| US1 (P1) | Phase 2 | US2, US3 (entrega MVP sozinha) |
| US2 (P1) | Phase 2, T013 usa T005 | US3 |
| US3 (P2) | Phase 2, T004/T006 | US1 parcialmente (rejeições já parseadas) |

### Within Each User Story

- Parser/modelos antes de providers
- Providers antes de UI
- Testes após implementação (validação, não TDD)

### Parallel Opportunities

- **Phase 1**: T002 em paralelo com T001
- **Phase 2**: T004 em paralelo com T003; T005 após T003
- **Após Phase 2**: US1 (T007–T012) e US2 (T013–T017) em paralelo por devs diferentes
- **US3**: T018, T021, T023 em paralelo
- **Polish**: T024, T025, T027 em paralelo

---

## Parallel Example: User Story 1

```bash
# Após T007, em paralelo:
Task T009: testes em sirene_app/test/mqtt_parser_test.dart
Task T010: log em sirene_app/lib/features/mqtt/mqtt_providers.dart

# Sequencial depois:
Task T011: validar processTestResult + itf_check_digit.dart
Task T012: validar modo reteste
```

---

## Parallel Example: User Story 2 + US3

```bash
# Dev A (US2):
Task T013: parseBatchEvent em mqtt_parser.dart
Task T014: sendSetBatch com ACK

# Dev B (US3) em paralelo:
Task T018: parseNvsFaultAlert
Task T021: rejection labels
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001–T002)
2. Phase 2: Foundational mínimo — T003 pode esperar; US1 precisa só do parser atual
3. **Atalho MVP**: T007–T012 (US1) — fix crítico de JSON colado
4. **VALIDAR**: `flutter test` + teste físico com payload colado simulado
5. Deploy se US1 validada

### Entrega incremental recomendada

1. Setup + US1 → **MVP produção** (elimina perda de aprovação)
2. US2 → confirmação explícita de lote
3. US3 → diagnóstico operacional
4. Polish → docs e E2E formal

### Escopo por prioridade do plan.md

| Prioridade | Tasks | Gap |
|------------|-------|-----|
| P0 | T007–T012 | G1 JSON colado |
| P1 | T013–T017, T018–T022 | G2 NVS, G3 batch ACK |
| P2 | T024–T027 | G5 OpenSpec, E2E |

---

## Notes

- Fix G1 (JSON colado) já implementado localmente em `mqtt_parser.dart` — T007 é finalizar/validar/commit
- Firmware `sirene-validator` v1.7.5 é referência; mudanças nesta feature são **no app e docs**, salvo validação cruzada
- Não gerar `dist/` sem confirmação do usuário (regra do projeto)
- Commitar após cada checkpoint de user story

---

## Task Summary

| Métrica | Valor |
|---------|-------|
| **Total de tarefas** | 27 |
| Setup | 2 |
| Foundational | 4 |
| US1 (P1) | 6 |
| US2 (P1) | 5 |
| US3 (P2) | 6 |
| Polish | 4 |
| **MVP sugerido** | T001–T002 + T007–T012 (8 tarefas) |
| **Paralelizáveis [P]** | 12 |

### Critérios de teste independente por story

| Story | Critério |
|-------|----------|
| US1 | Payload colado `APROVADO` → serial + registro DB |
| US2 | SET_BATCH → ACK ou heartbeat `BATCH_READY`; sequencial não regride |
| US3 | `lote_cheio` e `batch_nvs_fault` visíveis na UI do lote |
