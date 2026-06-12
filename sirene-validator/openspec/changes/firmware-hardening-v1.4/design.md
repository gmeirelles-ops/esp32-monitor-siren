## Context

Firmware `sirene-validator` v1.3.0 — appliance ESP32 de bancada com MQTT, PZEM, relé e fila offline SPIFFS. Análise identificou bugs e gaps de robustez. O operador usa **GPIO 0** para botão na bancada de teste — **não alterar**.

Restrições: sem mudança de contrato MQTT breaking (campos novos são aditivos); app Flutter pode ignorar ACK/heartbeat extra até atualizar.

## Goals / Non-Goals

**Goals:**

- Eliminar perda silenciosa de comandos e strings corrompidas
- Desacoplar medição PZEM do processamento MQTT
- Melhorar observabilidade (ACK, heartbeat com lote)
- Fonte única de regras FSM (`pure_logic`)
- Auto-encerramento por cota
- Versão 1.4.0 com testes host ampliados

**Non-Goals:**

- Alterar `GPIO_BUTTON` (permanece 0)
- MQTT TLS, auth, portal HTTPS, NVS encryption
- Refatoração completa de `main.c` em múltiplos arquivos (só extrações necessárias)
- Operador no firmware (continua no app)

## Decisions

### 1. Validação batch em `pure_logic`

Novas funções:

```c
bool pure_batch_fields_valid(const pure_batch_input_t *in);
bool pure_batch_copy_str(char *dst, size_t dst_len, const char *src);
bool pure_batch_same_op(const char *a, const char *b);
```

`main.c` parseia JSON → struct → valida → persiste. Testável no host sem cJSON no host (structs montadas nos testes).

### 2. SET_BATCH: preservar progresso no mesmo OP

| Condição | `aprovados` | `proximo_sequencial` |
|----------|-------------|----------------------|
| Mesmo `numero_op` | Mantém | Mantém, salvo payload > atual |
| OP diferente | Zera | Do payload |

Publicar ACK após save NVS bem-sucedido.

### 3. Task PZEM dedicada

```
worker_task          pzem_task
     │                    │
     ├─ botão ───────────►│ run_test_cycle()
     ├─ MQTT SET_BATCH    │ handle_calibration()
     └─ fila cmd          └─ bloqueia aqui (segundos)
```

- Fila de solicitações para `pzem_task`: `PZEM_WORK_TEST`, `PZEM_WORK_CALIBRATION`
- Flag `s_pzem_busy` — botão ignora se ocupado
- `state_machine` continua em `TESTING` durante ciclo

### 4. Fila MQTT: rejeição explícita

```c
if (xQueueSend(s_work_queue, &item, 0) != pdTRUE) {
    mqtt_bridge_publish_rejection("fila_cheia");
}
```

Manter tamanho 4; task PZEM separada reduz pressão na fila.

### 5. Calibração offline

`on_calibration_sample` chama `publish_or_queue("calibracao", json)` em vez de `mqtt_bridge_publish` direto.

### 6. Reconnect guard

```c
static volatile bool s_reconnect_scheduled;
// em DISCONNECTED: só xTaskCreate se !s_reconnect_scheduled
// em CONNECTED ou início da task: s_reconnect_scheduled = false
```

### 7. Heartbeat expandido

```json
{
  "uptime": 1234,
  "rssi": -45,
  "estado": "BATCH_READY",
  "fila": 0,
  "firmware_version": "1.4.0",
  "numero_op": "2026001",
  "proximo_sequencial": 3,
  "aprovados": 2
}
```

`telemetry_snapshot_t` ganha campos opcionais; provider em `main.c` preenche de `s_batch`.

### 8. Cota automática

Após `publish_test_result` em aprovação, se `pure_batch_quota_reached`:

```c
handle_end_batch(); // ou variante que publica evento cota_atingida antes de clear
```

`run_test_cycle` já bloqueia novo teste com `lote_cheio` — após auto-end, estado `IDLE` elimina confusão.

### 9. state_machine → pure_logic

Mapa `app_state_t` → `pure_state_t` em `state_machine.c`; cada `can_*` delega. `STATE_PROVISIONING` e `STATE_HARDWARE_FAULT` mapeiam para estados pure que negam teste/batch conforme tabela atual.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| ACK duplicado confunde app antigo | Campo `tipo:batch` distinto; app ignora se não conhecer |
| Burst de amostras calibração após offline | Documentar em TESTING.md; app deve tolerar |
| Race botão + pzem_task | `s_pzem_busy` + `button_set_test_in_progress` |
| SET_BATCH mesmo OP preserva sequencial | Documentar; app deve enviar `proximo_sequencial` correto em retomada |

## Migration Plan

1. Gravar firmware 1.4.0 por cabo na primeira vez (layout OTA inalterado — flash normal).
2. App Flutter: opcional consumir ACK e heartbeat; funciona sem atualização.
3. Bancada: revalidar checklist TESTING.md seções 10.2, 10.8 e novos cenários ACK/cota.
4. Rollback: reflash v1.3.0; NVS batch compatível.

## Open Questions

- Em `SET_BATCH` mesmo OP, permitir decrementar `proximo_sequencial` via payload ou só manter/máximo? **Decisão:** usar `max(atual, payload)` para evitar regressão acidental.
