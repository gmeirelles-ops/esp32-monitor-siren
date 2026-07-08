# Data Model: 004-local-line-actuator

## Firmware (NVS / RAM)

### `batch_context_t` (existente)

| Campo | Tipo | Uso |
|-------|------|-----|
| `potencia_min` | float | Limite inferior veredito local |
| `potencia_max` | float | Limite superior veredito local |
| `proximo_sequencial` | uint32 | Serial local |
| `aprovados` | uint32 | Contador lote |
| `modo_reteste` | bool | Suprime contador e atuador aprovação opcional |

Persistido via `batch_storage` — sobrevive reboot.

### `line_actuator_config_t` (novo)

| Campo | Tipo | Default | Validação |
|-------|------|---------|-----------|
| `reject_gpio` | int8 | Kconfig | ≥ 0 ou disabled |
| `reject_active_high` | bool | true | — |
| `reject_pulse_ms` | uint16 | 300 | 50–2000 |
| `approve_gpio` | int8 | -1 | Opcional (stack light verde) |
| `safe_on_fault` | enum | BOTH_OFF | BOTH_OFF, REJECT_ONLY |

### `pzem_cycle_result_t` (estendido v1.7.7)

| Campo | Tipo | Veredito teste | Calibração |
|-------|------|----------------|------------|
| `average_w` | float | ✓ | — |
| `max_w` | float | — | ✓ referência |
| `sample_count` | uint32 | diagnóstico | diagnóstico |

## MQTT (assíncrono, pós-decisão)

### `tipo:teste` (inalterado — ver `001-fw-sw-compat`)

Publicado **depois** de GPIO/LED. Campos críticos: `veredito`, `potencia_media`, `sequencial`, `ts_ms`.

### `tipo:rejeicao` (existente)

Quando teste nem inicia (lote cheio, PZEM fault) — distinto de reprovação pós-medição.

## App (SQLite / Firestore)

Sem mudança de veredito. Entidades existentes:

- `TestResult` — espelha MQTT
- `Product` — `potenciaRef`, tolerância → vira `SET_BATCH`
- `Batch` — estado UI; não bloqueia GPIO

## State Machine (interação)

```text
BATCH_READY --(botão)--> TESTING --(medição+veredito)--> BATCH_READY
                              |
                              +--> HARDWARE_FAULT (PZEM)
```

Durante `TESTING`: ignorar `SET_BATCH` ou enfileirar (política: rejeitar com `config_durante_teste`).

## Timing model

| Fase | Duração típica |
|------|----------------|
| Inrush discard | `INRUSH_DISCARD_MS` (~500 ms) |
| Amostragem | `tempo_teste_sec` (5–15 s) |
| Cálculo veredito | &lt; 1 ms |
| GPIO atuador | &lt; 50 ms alvo |
| MQTT publish | assíncrono / fila |
