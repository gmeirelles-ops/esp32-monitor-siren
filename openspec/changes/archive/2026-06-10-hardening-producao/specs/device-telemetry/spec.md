## ADDED Requirements

### Requirement: Presença online/offline via Last Will
O dispositivo SHALL anunciar presença `online` ao conectar ao broker e SHALL configurar um Last Will and Testament (LWT) que marque o dispositivo como `offline` em desconexão inesperada.

#### Scenario: Dispositivo conecta
- **WHEN** o dispositivo estabelece conexão com o broker MQTT
- **THEN** ele publica `online` no tópico de presença `sirene/<device_id>/presenca`

#### Scenario: Queda inesperada
- **WHEN** a conexão do dispositivo com o broker cai sem desconexão limpa
- **THEN** o broker publica a mensagem de LWT marcando `offline` no tópico de presença

### Requirement: Heartbeat periódico de saúde
O dispositivo SHALL publicar periodicamente um heartbeat contendo `uptime`, `rssi`, estado atual da FSM, profundidade da fila offline e versão de firmware.

#### Scenario: Publicação de heartbeat
- **WHEN** o intervalo de heartbeat configurado se completa e o dispositivo está conectado
- **THEN** ele publica em `sirene/<device_id>/heartbeat` um JSON com `uptime`, `rssi`, `estado`, `fila` e `firmware_version`

#### Scenario: Heartbeat suprimido offline
- **WHEN** o dispositivo está sem conexão com o broker no momento do heartbeat
- **THEN** ele não bloqueia a operação e retoma a publicação ao reconectar
