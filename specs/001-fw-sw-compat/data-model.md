# Data Model: Contrato Firmware × App

Entidades e campos que MUST permanecer sincronizados entre `sirene-validator` (firmware) e `sirene_app` (software).

## BatchConfig (comando SET_BATCH)

| Campo | Tipo | Validação | Dono da verdade |
|-------|------|-----------|-----------------|
| `cmd` | string | `"SET_BATCH"` | App publica |
| `numero_op` | string | 1–15 chars | App (formulário lote) |
| `id_produto` | string | `^\d{3}$` | App (catálogo produto) |
| `ano` | string | `^\d{2}$` | App (`resolveBatchYear`) |
| `tempo_teste` | int | 1–120 | App (produto) |
| `potencia_min` | float | ≥ 0, < max | App (produto, 2 dec.) |
| `potencia_max` | float | > min | App (produto, 2 dec.) |
| `quantidade_total` | int | > 0 | App (formulário) |
| `proximo_sequencial` | int | ≥ 1 | App DB + `sequencialInicial` |
| `modo_reteste` | bool | opcional | App toggle |

### Estado persistido no firmware (NVS)

| Campo | Transição |
|-------|-----------|
| `aprovados` | +1 em aprovação (não reteste) |
| `proximo_sequencial` | +1 em aprovação (não reteste); usado como serial do teste |
| `active` | true após SET_BATCH; false após END_BATCH |
| `modo_reteste` | atualizado via SET_BATCH |

### Estado espelhado no app

| Campo | Fonte |
|-------|-------|
| `activeBatch` | `setActiveBatch` após SET_BATCH |
| `retestModeProvider` | sync com `modo_reteste` |
| Contador serial local | `bumpSerialCounter` após aprovação |

---

## TestResultMessage (publicação status)

| Campo | Tipo | Firmware | App parse |
|-------|------|----------|-----------|
| `tipo` | string | `"teste"` | obrigatório |
| `ts_ms` | int64 | sim | ignorado |
| `ts_unix` | int64 | sim (0 se sem SNTP) | ignorado |
| `numero_op` | string | sim | sim |
| `id_produto` | string | sim | sim |
| `ano` | string | sim | sim |
| `veredito` | string | `APROVADO`\|`REPROVADO` | `isApprovedVeredito` |
| `potencia_media` | float | `%.2f` | double |
| `sequencial` | uint | usado no teste | serial ITF |
| `aprovados_no_lote` | uint | pós-lógica | auto-end-batch |

### Derivação de serial (somente app)

```
body = id_produto(3) + ano(2) + sequencial(4)
serial = body + ITF_check_digit(body)  → 10 dígitos
```

Firmware **não** publica serial — apenas `sequencial`.

---

## RejectionMessage

| Campo | Tipo |
|-------|------|
| `tipo` | `"rejeicao"` |
| `motivo` | string (30+ códigos firmware) |

Códigos críticos para produção: `lote_cheio`, `set_batch_campos_invalidos`, `cmd_durante_teste`, `batch_nvs_fault`, `pzem_ocupado`.

---

## HeartbeatMessage

| Campo | Uso no app |
|-------|------------|
| `estado` | FSM UI (`DeviceFsmState`) |
| `firmware_version` | display/sync |
| `bancada` | chave dispositivo `bancada-NN` |
| `numero_op`, `aprovados`, `proximo_sequencial` | dashboard (parcial) |
| `batch_nvs_fault` | **não parseado** |

### FSM (deve coincidir)

| String MQTT | Enum app |
|-------------|----------|
| `PROVISIONING` | provisioning |
| `IDLE` | idle |
| `BATCH_READY` | batchReady |
| `TESTING` | testing |
| `HARDWARE_FAULT` | hardwareFault |
| `OTA_UPDATING` | otaUpdating |

---

## CalibrationMessage

| tipo | evento | Campos |
|------|--------|--------|
| `calibracao_amostra` | `amostra` | `potencia_w`, `elapsed_ms` |
| `calibracao` | `iniciado` | — |
| `calibracao` | `concluido` | `potencia_media` |
| `calibracao` | `falha` | `motivo: pzem_uart` |

---

## EnsaioMessage

| evento | Campos |
|--------|--------|
| `iniciado` | `on_sec`, `off_sec`, `duracao_total_sec` |
| `ciclo` | `n`, `fase` (`ligado`\|`desligado`), `elapsed_sec` |
| `concluido` | `ciclos`, `elapsed_sec`, `motivo` |
| `falha` | `motivo` |

---

## Relacionamentos

```text
Product (app) ──limites──► BatchConfig ──MQTT SET_BATCH──► Firmware NVS
Firmware test ──MQTT teste──► TestResultMessage ──► Serial + DB + Firestore
Firmware reject ──MQTT rejeicao──► RejectionMessage ──► UI operador
Firmware heartbeat ──► DeviceInfo.estado + contadores
```
