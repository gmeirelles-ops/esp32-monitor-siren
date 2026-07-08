# Tasks: 004-local-line-actuator

**Input**: Design documents from `specs/004-local-line-actuator/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Bench físico e host tests onde indicado — spec não exige TDD formal.

**Organization**: Tarefas agrupadas por user story para entrega incremental independente.

## Speckit artifacts

- [x] spec.md
- [x] research.md
- [x] data-model.md
- [x] contracts/mqtt-config-and-actuator.md
- [x] plan.md
- [x] tasks.md
- [x] quickstart.md
- [x] bench-results.md (template para validação na bancada)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tarefas incompletas)
- **[USn]**: User story da [spec.md](./spec.md)

## Path Conventions

- Firmware: `sirene-validator/`
- App: `sirene_app/`
- Specs: `specs/004-local-line-actuator/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Versão, componente `line_actuator` e documentação de pinagem.

- [x] T001 Bump `FIRMWARE_VERSION` para `1.8.0` em `sirene-validator/components/board_config/include/board_config.h`
- [x] T002 [P] Criar componente `line_actuator`: `sirene-validator/components/line_actuator/CMakeLists.txt`, `Kconfig`, `include/line_actuator.h`, `line_actuator.c`; registrar em `sirene-validator/main/CMakeLists.txt`
- [x] T003 [P] Documentar pinagem proposta (`GPIO_REJECT`, polaridade, pulso ms) em `sirene-validator/components/board_config/include/board_config.h` e `specs/004-local-line-actuator/contracts/mqtt-config-and-actuator.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: API do atuador, ordem veredito→GPIO→MQTT, modo seguro em falha.

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase.

- [x] T004 Implementar `line_actuator_init`, `line_actuator_safe_all`, `line_actuator_on_approved`, `line_actuator_on_rejected` (pulso FreeRTOS timer) em `sirene-validator/components/line_actuator/line_actuator.c`
- [x] T005 Chamar `line_actuator_init()` no boot em `sirene-validator/main/main.c`
- [x] T006 Extrair helper `batch_cmd_apply_verdict` em `sirene-validator/main/batch_cmd.c` garantindo ordem: veredito → GPIO/LED → NVS → `publish_test_result`
- [x] T007 Invocar `line_actuator_safe_all()` em `hardware_fault_enter` (`sirene-validator/main/mqtt_cmd.c`) e callback PZEM fault em `sirene-validator/main/main.c`
- [x] T008 [P] Adicionar teste host de ordem lógica (veredito antes de publish) em `sirene-validator/host_tests/` ou comentário de contrato em `sirene-validator/components/pure_logic/`

**Checkpoint**: Atuador compilável; modo seguro em falha; ordem GPIO/MQTT documentada no código.

---

## Phase 3: User Story 1 — Separação física imediata (Priority: P1) 🎯 MVP

**Goal**: Pulso de refugo em `REPROVADO`; linha opera com broker offline.

**Independent Test**: [quickstart.md](./quickstart.md) cenário 1 — LED/atuador respondem com Wi-Fi down; fila offline recebe `tipo:teste`.

### Implementation for User Story 1

- [x] T009 [US1] Adicionar Kconfig `CONFIG_LINE_ACTUATOR_REJECT_GPIO`, `CONFIG_LINE_ACTUATOR_REJECT_PULSE_MS`, `CONFIG_LINE_ACTUATOR_ACTIVE_HIGH` em `sirene-validator/components/line_actuator/Kconfig`
- [x] T010 [US1] Integrar `line_actuator_on_rejected()` / `line_actuator_on_approved()` no fluxo pós-veredito em `sirene-validator/main/batch_cmd.c`
- [x] T011 [US1] Em `modo_reteste`, suprimir pulso de aprovação física (manter LED) conforme edge case em `specs/004-local-line-actuator/spec.md`
- [x] T012 [US1] Medir latência &lt; 50 ms pós-última amostra com `esp_timer_get_time()` entre fim de `pzem_measure_cycle` e GPIO em `sirene-validator/main/batch_cmd.c`
- [x] T013 [P] [US1] Publicação opcional `tipo:atuador` em `sirene-validator/main/batch_cmd.c` (telemetria P2)
- [ ] T014 [US1] Validar fila offline com broker down — registrar resultado em `specs/004-local-line-actuator/bench-results.md`
- [ ] T015 [US1] Build + flash via `sirene-validator/scripts/build_and_flash_windows.ps1`

**Checkpoint**: Refugo físico funcional; offline validado na bancada.

---

## Phase 4: User Story 2 — Tempo de ciclo otimizado (Priority: P1)

**Goal**: Leitura PZEM mais rápida; teste isolado de interferência Wi-Fi.

**Independent Test**: [quickstart.md](./quickstart.md) cenários 2–4; redução ≥ 30% tempo de leitura documentada.

### Implementation for User Story 2

- [x] T016 [P] [US2] Adicionar `pzem_read_active_power_w()` com retries reduzidos em `sirene-validator/components/pzem/pzem.c` e `include/pzem.h`
- [x] T017 [US2] Kconfig `CONFIG_PZEM_FAST_READ` e branch em `pzem_measure_cycle` em `sirene-validator/components/pzem/pzem.c`
- [x] T018 [P] [US2] Log de duração por amostra (`ESP_LOGD`, tag `pzem`) para benchmark em `sirene-validator/components/pzem/pzem.c`
- [x] T019 [US2] Migrar `pzem_worker_task` para `xTaskCreatePinnedToCore(..., CONFIG_PZEM_WORKER_CORE)` em `sirene-validator/main/main.c`
- [x] T020 [P] [US2] Kconfig `CONFIG_PZEM_WORKER_CORE` (default 0) em `sirene-validator/main/Kconfig` ou componente `pzem`
- [ ] T021 [US2] Benchmark 100 leituras antes/depois → `specs/004-local-line-actuator/bench-results.md`
- [ ] T022 [US2] Stress test Wi-Fi reconnect durante ciclo (quickstart §4)

**Checkpoint**: PZEM benchmark documentado; ciclo não trava com reconnect Wi-Fi.

---

## Phase 5: User Story 3 — Configuração gerencial (Priority: P2)

**Goal**: App como painel; rejeitar config durante teste; sem recálculo de veredito no app.

**Independent Test**: Alterar limites via `SET_BATCH`; próximo teste usa NVS; app confia em `veredito` MQTT.

### Implementation for User Story 3

- [x] T023 [US3] Rejeitar `SET_BATCH` durante `STATE_TESTING` com motivo `config_durante_teste` em `sirene-validator/main/mqtt_cmd.c`
- [x] T024 [P] [US3] Auditar `sirene_app/lib/features/mqtt/mqtt_providers.dart` `processTestResult` — garantir veredito MQTT como fonte da verdade; adicionar teste em `sirene_app/test/` se ausente
- [x] T025 [US3] Atualizar `openspec/specs/batch-test-execution/spec.md` com ordem GPIO→MQTT e papel do app
- [ ] T026 [US3] Validar `SET_BATCH` com novos limites → próximo teste usa NVS (cenário config no quickstart)

**Checkpoint**: Config mid-teste rejeitada; app documentado como painel.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentação final, testes host, aceite.

- [x] T027 [P] Atualizar `specs/004-local-line-actuator/quickstart.md` com checkboxes de aceite preenchíveis
- [x] T028 [P] Atualizar `openspec/specs/offline-resilience/spec.md` se necessário após bench US1
- [x] T029 Executar `sirene-validator/scripts/run_host_tests.sh`
- [x] T030 Revisar cabeçalho Speckit artifacts neste `tasks.md` após conclusão de cada fase

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Phase 1 — **bloqueia** todas as user stories
- **US1 (Phase 3)**: Depende de Phase 2 — **MVP**
- **US2 (Phase 4)**: Depende de Phase 2; paralelo com US1 após T006 (arquivos distintos)
- **US3 (Phase 5)**: Depende de Phase 2; paralelo com US1/US2
- **Polish (Phase 6)**: Depende das user stories desejadas concluídas

### User Story Dependencies

| Story | Depende de | Independente de |
|-------|------------|-----------------|
| US1 | Phase 2 | US2, US3 |
| US2 | Phase 2 | US1, US3 (após T006) |
| US3 | Phase 2 | US1, US2 |

### Within Each User Story

- Kconfig antes de integração em `batch_cmd.c` (US1)
- `pzem_read_active_power_w` antes de `CONFIG_PZEM_FAST_READ` branch (US2)
- Rejeição `SET_BATCH` antes de validação quickstart (US3)

### Parallel Opportunities

- **Phase 1**: T002 ∥ T003
- **Phase 2**: T008 ∥ T004–T007 (após T004 API definida)
- **Phase 3+4**: US1 (`batch_cmd.c`) ∥ US2 (`pzem.c`, `main.c`) após Phase 2
- **Phase 5**: T024 ∥ T023
- **Phase 6**: T027 ∥ T028

---

## Parallel Example: User Story 1 + 2

```bash
# Após Phase 2 completa, duas frentes em paralelo:

# Dev A — atuador (US1)
# T009–T015 em sirene-validator/main/batch_cmd.c e line_actuator/

# Dev B — PZEM (US2)
# T016–T022 em sirene-validator/components/pzem/pzem.c e main.c
```

## Parallel Example: User Story 1

```bash
# Dentro de US1, após T010:
# T013 (telemetria atuador) em paralelo com T012 (medição latência)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar Phase 1: Setup (T001–T003)
2. Completar Phase 2: Foundational (T004–T008) — **obrigatório**
3. Completar Phase 3: User Story 1 (T009–T015)
4. **PARAR e VALIDAR**: quickstart cenário 1 (broker offline + atuador)
5. Demo na bancada antes de US2/US3

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 → refugo físico + offline → **MVP deployável**
3. US2 → throughput PZEM + dual-core
4. US3 → hardening config + auditoria app
5. Polish → docs e host tests

### Parallel Team Strategy

1. Time completa Phase 1–2 junto
2. Após Phase 2:
   - Dev A: US1 (atuador)
   - Dev B: US2 (PZEM/core)
   - Dev C: US3 (MQTT + app audit)
3. Polish conjunto

---

## Notes

- Veredito **já é local** em `batch_cmd_run_test_cycle` — não duplicar lógica no app
- `GPIO_RELAY` = carga sirene; `GPIO_REJECT` = refugo (novo)
- Build Windows: usar `BUILD-E-GRAVAR-FIRMWARE.bat` ou `sirene-validator/scripts/build_and_flash_windows.ps1` (sync para `C:\dev\sv_firmware_src`)
- Calibração usa `max_w` (v1.7.7); teste de produção mantém **média** — ver [research.md](./research.md) R6

---

## Task Summary

| Phase | Tasks | Done | Bench |
|-------|-------|------|-------|
| Setup | T001–T003 | 3/3 | — |
| Foundational | T004–T008 | 5/5 | — |
| US1 (P1) MVP | T009–T015 | 5/7 | T014, T015 |
| US2 (P1) | T016–T022 | 5/7 | T021, T022 |
| US3 (P2) | T023–T026 | 3/4 | T026 |
| Polish | T027–T030 | 4/4 | — |
| **Total** | **30** | **25/30** | **5 bancada** |

**MVP scope**: T001–T015 (Phase 1–3) — código pronto; falta flash + bench T014–T015
