## Context

Firmware `sirene-validator` v1.4.0 em ESP32 com PZEM-004T via Modbus RTU (9600, addr `0xF8`, UART2). Mapa GPIO atual em `board_config.h`:

| Função | GPIO |
|--------|------|
| Relé | 4 |
| Botão | 5 |
| PZEM TX (ESP → módulo) | 27 |
| PZEM RX (ESP ← módulo) | 26 |

Ligação UART **cruzada**: ESP32 TX(27) → RX PZEM; ESP32 RX(26) ← TX PZEM; **GND comum**.

Análise do driver (`pzem.c`) identificou lacunas prováveis da falha em campo:

1. **Sem delay após envio Modbus** — PZEM-004T tipicamente responde em 50–200 ms; leitura imediata retorna timeout/CRC inválido.
2. **Sem `uart_wait_tx_done`** — bytes podem ainda estar no buffer TX ao iniciar leitura.
3. **Sem log de diagnóstico** — operador vê apenas `HARDWARE_FAULT` genérico.
4. **Documentação desatualizada** — guia ainda cita GPIO 16/17.

OTA via MQTT **já implementado** (`handle_ota_update` + `ota_update_start`); falta apenas operacionalização.

## Goals / Non-Goals

**Goals:**

- Leitura confiável do PZEM-004T com hardware ligado conforme mapa 4/5/26/27
- Visibilidade de falha UART (logs + MQTT) desde o boot
- Procedimento OTA reproduzível por qualquer operador técnico
- Documentação alinhada ao hardware real

**Non-Goals:**

- Endereço Modbus dinâmico ou scan de barramento
- OTA sem URL HTTP(S) (sem transferência MQTT binária inline)
- Mudança de broker ou tópicos MQTT

## Decisions

### 1. Timing Modbus RTU

```c
#define PZEM_RESPONSE_DELAY_MS   100   /* após TX completo, antes de RX */
#define PZEM_READ_TIMEOUT_MS     300   /* timeout uart_read_bytes */
```

Fluxo em `pzem_send_read_power`:

```
uart_flush → write request → uart_wait_tx_done → delay 100ms → read response
```

Justificativa: bibliotecas de referência (PZEM004Tv30 Arduino) usam 100–200 ms entre request e parse.

### 2. Validação de resposta

Além de addr/func/CRC, validar `resp[2] == 2` (1 registrador = 2 bytes de dados).

Em falha, logar com `ESP_LOGW`: `len`, hex dump dos primeiros 16 bytes, motivo (`timeout`, `addr`, `crc`, `bytecount`).

### 3. Autoteste no boot

Após `pzem_init`, executar até 3 tentativas de `pzem_read_power_w`. Se todas falharem:

- Publicar alerta `{"tipo":"hardware","falha":"pzem_uart_boot"}`
- Transicionar para `STATE_HARDWARE_FAULT` (comportamento existente via callback)

Se uma leitura OK (mesmo 0 W sem carga), considerar UART funcional.

### 4. Comando MQTT `PZEM_PROBE`

Payload:

```json
{ "cmd": "PZEM_PROBE" }
```

Resposta em `status`:

```json
{
  "tipo": "pzem",
  "evento": "probe",
  "potencia_w": 0.0,
  "uart_ok": true
}
```

Rejeitado durante `TESTING` e `OTA_UPDATING` (mesma guarda de `OTA_UPDATE`). Não energiza relé.

### 5. OTA — nenhuma mudança de código necessária

Manter `OTA_UPDATE` existente. Entregar:

- Script `scripts/serve_firmware_and_ota.sh` que:
  1. Copia `build/sirene-validator.bin` para diretório servido
  2. Sobe `python3 -m http.server 8080`
  3. Publica MQTT `OTA_UPDATE` com URL LAN
  4. Assina `status` por eventos `tipo:ota`

- Seção em `GUIA_COMPLETO.md` com checklist numerado (build → servir → MQTT → confirmar heartbeat).

### 6. Versão

Bump para `1.4.1` — correção PZEM + docs; sem breaking change MQTT.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Delay 100 ms reduz taxa de amostragem | Ciclo de teste usa intervalo 100 ms já; impacto nulo |
| PZEM com endereço ≠ 0xF8 | Documentar reset de fábrica; probe reporta `uart_ok:false` |
| Nível lógico 3.3 V vs 5 V PZEM | Documentar necessidade de level shifter ou módulo 3.3 V compatível |
| OTA HTTP sem TLS | Aceito em LAN industrial isolada (já decisão v1.4) |

## Open Questions

- Confirmar se o módulo PZEM em uso é **004T v3.0** (addr 0xF8) ou clone com addr 0x01 — probe ajuda a diagnosticar.
- Confirmar alimentação 5 V do PZEM e GND comum com ESP32.
