## Context

Change `firmware-queue-and-command-fixes` adicionou sufixo de tópico na fila e host tests para cota de lote. Telemetria atual: estado FSM, RSSI, uptime, fila, firmware_version.

## Goals / Non-Goals

**Goals:**
- Observabilidade sem aumentar tráfego MQTT além do heartbeat existente (30s).
- Host tests reproduzíveis no CI (`add-ci-pipeline`).

**Non-Goals:**
- Prometheus/Grafana nesta change.
- Remote logging para nuvem.

## Decisions

### 1. Contadores em NVS

**Decisão:** `reboot_count` e `watchdog_resets` persistidos em NVS, incrementados no boot.

### 2. Heartbeat JSON estendido

**Decisão:** campos opcionais novos; app ignora se ausentes (firmware antigo).

### 3. Host tests offline queue

**Decisão:** extrair lógica de serialização da fila para testável em `pure_logic` ou módulo `offline_queue_logic` sem ESP-IDF.

### 4. Logs

**Decisão:** `ESP_LOGI` com tag fixa `SIRENE` e código de evento (`QUEUE_DRAIN`, `CMD_REJECT`, etc.).

## Risks / Trade-offs

- **[Payload heartbeat maior]** → ~50 bytes extras; aceitável.

## Migration Plan

1. OTA firmware com novos campos.
2. App atualizado para exibir métricas quando presentes.

## Open Questions

- Persistir histórico de falhas PZEM na NVS ou só contador de sessão?
