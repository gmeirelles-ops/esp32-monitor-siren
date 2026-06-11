## ADDED Requirements

### Requirement: Contrato do comando OTA_UPDATE
O dispositivo SHALL aceitar, no tópico `sirene/<device_id>/comando`, um payload JSON com `cmd` igual a `OTA_UPDATE` contendo a `url` da imagem de firmware.

#### Scenario: Payload OTA_UPDATE válido
- **WHEN** chega um JSON com `cmd: "OTA_UPDATE"` e `url` não vazia
- **THEN** o dispositivo aceita o comando e inicia o processo de atualização OTA

#### Scenario: OTA_UPDATE sem url
- **WHEN** chega um payload `OTA_UPDATE` sem o campo `url` ou com `url` vazia
- **THEN** o dispositivo descarta o comando e publica uma mensagem de rejeição

### Requirement: Tópicos de telemetria do dispositivo
O dispositivo SHALL publicar presença e heartbeat em tópicos dedicados endereçados por dispositivo.

#### Scenario: Tópicos de telemetria
- **WHEN** o dispositivo está conectado ao broker
- **THEN** ele utiliza `sirene/<device_id>/presenca` para presença (online/offline via LWT) e `sirene/<device_id>/heartbeat` para o heartbeat periódico
