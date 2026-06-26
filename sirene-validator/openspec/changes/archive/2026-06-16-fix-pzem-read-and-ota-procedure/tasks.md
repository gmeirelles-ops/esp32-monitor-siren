## 1. board_config — timing e versão



- [x] 1.1 Adicionar `PZEM_RESPONSE_DELAY_MS` (100) e `PZEM_READ_TIMEOUT_MS` (300) em `board_config.h`

- [x] 1.2 Bump `FIRMWARE_VERSION` para `1.4.1`



## 2. Driver PZEM — confiabilidade UART



- [x] 2.1 Em `pzem_send_read_power`: `uart_wait_tx_done` + delay pós-TX antes de `uart_read_bytes`

- [x] 2.2 Validar `resp[2] == 2` (byte-count Modbus)

- [x] 2.3 Log hex dump e motivo de falha (`timeout`, `addr`, `func`, `bytecount`, `crc`) via `ESP_LOGW`

- [x] 2.4 Usar `PZEM_READ_TIMEOUT_MS` no timeout de leitura



## 3. Autoteste boot



- [x] 3.1 Após `pzem_init` em `main.c`, executar até 3 tentativas de leitura

- [x] 3.2 Se todas falharem, publicar alerta `pzem_uart_boot` e acionar fault existente

- [x] 3.3 Log `ESP_LOGI` com resultado do autoteste (potência lida ou falha)



## 4. Comando MQTT PZEM_PROBE



- [x] 4.1 Adicionar handler `PZEM_PROBE` em `process_mqtt_payload`

- [x] 4.2 Publicar resposta `tipo:pzem` em `status` com `potencia_w` e `uart_ok`

- [x] 4.3 Incluir `PZEM_PROBE` na lista de comandos bloqueados durante teste/calibração



## 5. OTA operacional (sem mudança de código OTA)



- [x] 5.1 Criar `scripts/serve_firmware_and_ota.sh` (serve HTTP + mosquitto_pub + sub status)

- [x] 5.2 Adicionar seção **Passo a passo OTA** em `docs/GUIA_COMPLETO.md`

- [x] 5.3 Atualizar mapa GPIO em `docs/GUIA_COMPLETO.md` (4/5/26/27)

- [x] 5.4 Atualizar `docs/TESTING.md` — cenários `PZEM_PROBE` e checklist OTA



## 6. Validação



- [x] 6.1 `./scripts/run_host_tests.sh` sem regressão

- [x] 6.2 `idf.py build` sem erros

- [ ] 6.3 Teste em bancada: `PZEM_PROBE` retorna `uart_ok:true` com PZEM ligado

- [ ] 6.4 Teste OTA: heartbeat reporta `firmware_version":"1.4.1"` após update

