## ADDED Requirements

### Requirement: Reconexão MQTT após alteração de broker
O dispositivo SHALL reconectar ao broker correto após re-provisionamento ou boot com configuração NVS de broker distinta do fallback de compilação.

#### Scenario: Boot com broker NVS
- **WHEN** o dispositivo reinicia após provisionamento com `mqtt_cfg` gravado
- **THEN** o cliente MQTT inicializa com a URI da NVS e publica presença `online` no broker configurado

#### Scenario: Falha de conexão ao broker configurado
- **WHEN** o broker da NVS está inacessível
- **THEN** o dispositivo aplica backoff exponencial de reconexão MQTT sem bloquear testes locais por botão físico
