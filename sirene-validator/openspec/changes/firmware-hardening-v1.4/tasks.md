## 1. pure_logic — validação e strings

- [x] 1.1 Adicionar `pure_batch_input_t` e `pure_batch_fields_valid()` em `pure_logic.h/.c`
- [x] 1.2 Adicionar `pure_batch_copy_str()` com garantia de null terminator
- [x] 1.3 Adicionar `pure_batch_same_op()` para semântica de reenvio SET_BATCH
- [x] 1.4 Criar `host_tests/test_batch_validation.c` com casos positivos e negativos
- [x] 1.5 Registrar novos testes em `host_tests/CMakeLists.txt` e `test_main.c`

## 2. SET_BATCH — parsing e lifecycle

- [x] 2.1 Refatorar `parse_set_batch()` para usar `pure_batch_copy_str` e `pure_batch_fields_valid`
- [x] 2.2 Implementar preservação de `aprovados`/sequencial quando mesmo `numero_op`
- [x] 2.3 Publicar ACK `{"tipo":"batch","evento":"configurado",...}` após save bem-sucedido
- [x] 2.4 Implementar auto-`END_BATCH` com evento `cota_atingida` após última aprovação

## 3. Task PZEM dedicada

- [x] 3.1 Criar `pzem_task` com fila de trabalho (teste / calibração)
- [x] 3.2 Mover `run_test_cycle` e `handle_start_calibration` para execução na pzem_task
- [x] 3.3 Ajustar `worker_task` para enfileirar trabalho PZEM em vez de bloquear
- [x] 3.4 Garantir `button_set_test_in_progress` e flag busy durante ciclo PZEM

## 4. MQTT — fila e reconnect

- [x] 4.1 Publicar `fila_cheia` quando `xQueueSend` para `s_work_queue` falhar
- [x] 4.2 Adicionar guard `s_reconnect_scheduled` em `mqtt_bridge.c`
- [x] 4.3 Resetar guard em `MQTT_EVENT_CONNECTED` e ao iniciar task de reconnect

## 5. Calibração offline

- [x] 5.1 Alterar `on_calibration_sample` para usar `publish_or_queue("calibracao", ...)`

## 6. Telemetria e state_machine

- [x] 6.1 Estender `telemetry_snapshot_t` com campos de lote
- [x] 6.2 Preencher campos no provider `telemetry_snapshot()` em `main.c`
- [x] 6.3 Atualizar JSON do heartbeat em `telemetry.c`
- [x] 6.4 Delegar `state_machine_can_*` para funções `pure_fsm_*` com mapa de estados

## 7. Versão e documentação

- [x] 7.1 Bump `FIRMWARE_VERSION` para `1.4.0` em `board_config.h`
- [x] 7.2 Atualizar `docs/GUIA_COMPLETO.md` — ACK batch, heartbeat, cota automática, SET_BATCH mesmo OP
- [x] 7.3 Atualizar `docs/TESTING.md` — cenários ACK, fila_cheia, cota auto-end, calibração offline
- [x] 7.4 Executar `./scripts/run_host_tests.sh` e `idf.py build` sem erros
