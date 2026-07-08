# Bench results — 004-local-line-actuator

Preencher na bancada após flash firmware **1.8.0**.

## US1 — Atuador + offline (T014)

| Cenário | Data | Resultado | Notas |
|---------|------|-----------|-------|
| 10 testes broker down, contadores NVS OK | | ☐ | |
| Pulso `GPIO_REJECT` em REPROVADO | | ☐ | Osciloscópio / LED |
| `verdict_gpio_latency_us` &lt; 50000 no log | | ☐ | tag `batch_cmd` |
| Fila offline drena ao reconectar | | ☐ | |

## US2 — PZEM benchmark (T021)

Baseline: firmware **1.7.7**, `CONFIG_PZEM_FAST_READ=n`  
Target: firmware **1.8.0**, `CONFIG_PZEM_FAST_READ=y`

| Métrica | 1.7.7 (ms) | 1.8.0 (ms) | Δ % |
|---------|------------|------------|-----|
| Média por amostra (100 reads) | | | |
| Ciclo completo 5 s | | | |

Log tag `pzem`: `active_power_read_us=...`

## US2 — Wi-Fi stress (T022)

| Cenário | Resultado | Notas |
|---------|-----------|-------|
| Reconnect AP durante teste 10 s | ☐ | Sem WDT reset |
| Duração ciclo ±5% | ☐ | |

## US3 — Config NVS (T026)

| Cenário | Resultado |
|---------|-----------|
| `SET_BATCH` novos limites em BATCH_READY → próximo teste usa NVS | ☐ |
| `SET_BATCH` durante TESTING → `config_durante_teste` | ☐ |
