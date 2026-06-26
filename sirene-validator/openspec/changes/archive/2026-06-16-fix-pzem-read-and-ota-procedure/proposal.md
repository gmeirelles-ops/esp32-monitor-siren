## Why

Em bancada com GPIO relé **4**, botão **5**, UART PZEM **TX=27 / RX=26**, o operador **não consegue ler dados do PZEM-004T**. O driver Modbus atual não aguarda resposta após o envio, não registra falhas UART e não faz autoteste no boot — o que impede diagnóstico. A documentação (`GUIA_COMPLETO.md`) ainda cita GPIOs antigos (16/17, relé 26, botão 27), aumentando risco de ligação errada.

O comando **OTA via MQTT** (`OTA_UPDATE`) **já existe** desde v1.4.0, mas não há guia operacional claro para o time de produção (servir `.bin`, publicar comando, validar versão).

## What Changes

- Endurecer driver PZEM: `uart_wait_tx_done`, delay pós-envio, timeout configurável, validação de byte-count Modbus, log hex em falha.
- Autoteste PZEM no boot: leitura de potência + alerta MQTT se falhar 3× consecutivas.
- Comando MQTT **`PZEM_PROBE`** (ou leitura pontual em `status`) para diagnóstico remoto sem iniciar teste.
- Atualizar `board_config.h` com constantes de timing UART (`PZEM_RESPONSE_DELAY_MS`, `PZEM_READ_TIMEOUT_MS`).
- Corrigir documentação de GPIO e ligação PZEM (4/5/26/27).
- Adicionar script `scripts/serve_firmware_and_ota.sh` e seção **passo a passo OTA** em `docs/GUIA_COMPLETO.md`.
- Bump `FIRMWARE_VERSION` para `1.4.1`.

## Explicitly Out of Scope

- Suporte a endereço Modbus configurável em runtime (permanece `0xF8` de fábrica).
- OTA por HTTPS com certificado pinning (HTTP LAN continua aceito).
- Alteração de particionamento flash.
- App Flutter — consumo de `PZEM_PROBE` é opcional.

## Capabilities

### New Capabilities

- `pzem-uart-reliability`: Timing, validação e logs no driver Modbus PZEM-004T
- `pzem-boot-probe`: Autoteste e alerta de falha UART no boot
- `pzem-mqtt-probe`: Comando MQTT de diagnóstico pontual
- `ota-operational-guide`: Script e documentação passo a passo para OTA via MQTT

### Modified Capabilities

- `telemetry-batch-fields`: Heartbeat pode incluir flag `pzem_ok` (aditivo, não breaking)

## Impact

| Área | Impacto |
|------|---------|
| `components/pzem/pzem.c` | Timing UART, logs, API de probe |
| `components/board_config/include/board_config.h` | Novos defines de timing; bump versão |
| `main/main.c` | Handler `PZEM_PROBE`, autoteste boot |
| `docs/GUIA_COMPLETO.md` | GPIO correto + guia OTA passo a passo |
| `docs/TESTING.md` | Cenários PZEM probe e OTA |
| `scripts/serve_firmware_and_ota.sh` | Novo script operacional |
