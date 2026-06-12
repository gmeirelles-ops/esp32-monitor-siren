## Why

O app companion descobre dispositivos via MQTT, mas o monitoramento operacional tem lacunas que confundem o operador na linha: alertas de hardware PZEM nunca são limpos após recuperação, dispositivos permanecem "online" quando o heartbeat para (LWT não dispara em quedas parciais), e rejeições de comandos MQTT (`tipo: rejeicao`) são recebidas mas ignoradas silenciosamente. Na bancada real, isso gera falso positivo de falha e impede diagnóstico de `SET_BATCH` rejeitado.

## What Changes

- **App**: timeout de stale heartbeat — marcar offline se não houver `heartbeat`/`presenca` por intervalo configurável (padrão 90 s).
- **App**: limpar alerta de hardware quando FSM sair de `HARDWARE_FAULT` ou ao receber mensagem de recuperação.
- **App**: exibir rejeições MQTT ao operador (snackbar na tela de lote + lista recente em dispositivos).
- **Firmware**: publicar alerta de recuperação de hardware ao sair de `HARDWARE_FAULT` (`{"tipo":"hardware","evento":"recuperado"}`).
- **Firmware**: registrar `hw_mon` no Task Watchdog (consistência com `telemetry`/`offline_sync`).
- **Specs**: preencher `Purpose` em `device-monitoring` e `hardware-monitoring` (hoje TBD).

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `device-monitoring`: Timeout de stale heartbeat; limpeza de alertas; exibição de rejeições MQTT.
- `hardware-monitoring`: Publicação de evento de recuperação ao restabelecer comunicação PZEM.
- `mqtt-client`: Processamento de mensagens `tipo: rejeicao` com feedback ao operador.
- `system-robustness`: Tarefa `hw_mon` monitorada pelo TWDT.

## Impact

- **App Flutter**: `mqtt_providers.dart`, `devices_screen.dart`, `device_detail_screen.dart`, `batch_screen.dart`, `mqtt_messages.dart`.
- **Firmware**: `main.c` (`on_pzem_fault`, `hardware_monitor_task`), possivelmente contrato em `mqtt-messaging`.
- **Sem breaking change**: Mensagens existentes preservadas; recuperação é aditiva.
