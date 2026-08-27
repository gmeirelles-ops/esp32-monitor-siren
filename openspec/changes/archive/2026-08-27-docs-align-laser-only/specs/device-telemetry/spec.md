## ADDED Requirements

### Requirement: Heartbeat a cada 10 segundos
O firmware SHALL publicar heartbeat no tópico `{site}/bancada-{NN}/heartbeat` a cada **10** segundos (`HEARTBEAT_INTERVAL_SEC`), e a documentação dessa capability SHALL refletir o mesmo valor.

#### Scenario: Intervalo operacional
- **WHEN** o dispositivo está conectado ao broker
- **THEN** heartbeats sucessivos ocorrem com intervalo nominal de 10 s
