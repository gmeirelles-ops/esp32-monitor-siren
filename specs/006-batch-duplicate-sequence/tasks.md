# Tasks: 006-batch-duplicate-sequence

## Phase 0 — Design ✓

- [x] research.md
- [x] data-model.md
- [x] contracts/mqtt-batch-reset.md
- [x] contracts/mqtt-rejection-codes.md
- [x] quickstart.md
- [x] plan.md

## Phase 1 — Firmware ✓

- [x] F1: SET_BATCH reset (remove same_op preservation)
- [x] F1: app_last_test_clear em SET_BATCH e END_BATCH
- [x] F2: Cooldown pós-aprovação + peca_ja_aprovada
- [x] F2: host_tests/test_batch_cooldown.c
- [x] Kconfig CONFIG_SIRENE_POST_APPROVAL_COOLDOWN_MS

## Phase 2 — App ✓

- [x] A1: Dedupe testExistsByOpAndTsMs
- [x] A2: Watchdog 15s Testando/Aguardando MQTT
- [x] A3: _reconcileFromHeartbeat + proximoSequencial UI
- [x] A4: Offline OLED hint + reconciliação ao reconectar
- [x] A5: resolveNewBatchSequencial + setActiveBatch limpo

## Phase 3 — Testes e docs ✓

- [x] test_dedupe_ts_ms_test.dart atualizado
- [x] batch_serial_logic_test.dart resolveNewBatchSequencial
- [x] GUIA_COMPLETO.md SET_BATCH + peca_ja_aprovada
- [x] specs/003 contract dedupe nota

## Phase 4 — Validação bancada

- [ ] quickstart.md cenários 1–7 em hardware real — ver [bench-validation.md](bench-validation.md)
- [x] Testes Sprint A automatizados (`batch_integrity_sprint_a_test.dart`)
