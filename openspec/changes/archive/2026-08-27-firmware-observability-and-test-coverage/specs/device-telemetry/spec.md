## MODIFIED Requirements

### Requirement: Heartbeat periódico
O dispositivo SHALL publicar heartbeat periódico em `sirene/<device_id>/heartbeat` contendo estado FSM, RSSI, uptime, profundidade da fila offline, versão de firmware e contadores de saúde (`reboot_count`, `watchdog_resets` quando disponíveis).

#### Scenario: Heartbeat em operação normal
- **WHEN** o dispositivo está online e conectado ao broker
- **THEN** publica heartbeat no intervalo configurado com todos os campos de telemetria incluindo contadores de reinício

#### Scenario: Firmware legado no app
- **WHEN** o heartbeat não contém os novos campos opcionais
- **THEN** o app exibe telemetria disponível sem erro
