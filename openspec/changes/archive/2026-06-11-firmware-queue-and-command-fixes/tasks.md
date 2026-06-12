## 1. Fila offline com tópico

- [x] 1.1 Estender `offline_queue.h` com `offline_queue_push(const char *topic_suffix, const char *json)` e peek que devolve tópico + payload
- [x] 1.2 Gravar envelope JSON `{"topic":"…","payload":…}` em SPIFFS; fallback `status` para entradas legadas sem campo `topic`
- [x] 1.3 Atualizar `drain_queue()` para publicar no sufixo persistido
- [x] 1.4 Atualizar `publish_or_queue()` em `main.c` para passar `topic_suffix` ao push

## 2. Comandos MQTT sem execução tardia

- [x] 2.1 Em `on_mqtt_command()`, parse rápido de `cmd` e rejeitar com `cmd_durante_teste` quando `STATE_TESTING` ou `s_calibrating`
- [x] 2.2 Aplicar guard a `SET_BATCH`, `END_BATCH`, `START_CALIBRATION` e `OTA_UPDATE` antes de `xQueueSend`
- [x] 2.3 Confirmar que comandos válidos fora de teste/calibração continuam enfileirados e processados como hoje

## 3. Resiliência PZEM

- [x] 3.1 Adicionar `PZEM_SAMPLE_READ_RETRIES` em `board_config.h` (padrão 3)
- [x] 3.2 Implementar retentativas por intervalo de amostra em `pzem_measure_cycle()`; pular amostra após esgotar retries
- [x] 3.3 Manter falha de ciclo apenas quando `sample_count == 0` após inrush

## 4. Cota de lote (`quantidade_total`)

- [x] 4.1 Adicionar `pure_batch_quota_reached()` em `pure_logic` e testes host
- [x] 4.2 No início de `run_test_cycle()`, bloquear teste se cota atingida; sinal LED e rejeição `lote_cheio` via MQTT quando conectado
- [x] 4.3 Garantir que reprovações não incrementam bloqueio além de aprovados

## 5. Verificação

- [x] 5.1 Adicionar/atualizar testes host (`test_batch_quota.c` ou extensão de `test_fsm.c`) e rodar `scripts/run_host_tests.sh`
- [x] 5.2 Build firmware `idf.py build` sem erros
- [x] 5.3 Smoke manual documentado: fila offline de alerta → tópico `alerta`; `END_BATCH` durante teste → rejeição imediata; botão após meta → bloqueio
