## Why

O firmware já publica heartbeat e alertas, mas faltam métricas estruturadas para diagnóstico em escala (reboots por watchdog, profundidade média da fila offline, taxa de falha PZEM) e host tests para edge cases da fila SPIFFS e política de retenção.

## What Changes

- Campos adicionais no heartbeat: `reboot_count`, `watchdog_resets`, `pzem_failures_session`.
- Log estruturado (nível INFO) para eventos críticos: drain fila, rejeição de comando, lote cheio.
- Host tests: fila offline com sufixo de tópico, limite FIFO, entrada legada sem metadado.
- Script de bancada documentado para queda de energia simulada.
- App pode exibir novos campos no detalhe do dispositivo (opcional v1).

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `device-telemetry`: métricas adicionais no heartbeat
- `offline-resilience`: testes host da fila SPIFFS
- `device-monitoring`: exibição de métricas de saúde no app

## Impact

- **Firmware**: `telemetry`, `offline_queue`, `host_tests`
- **App** (opcional): `device_detail_screen.dart`, `mqtt_parser.dart`
