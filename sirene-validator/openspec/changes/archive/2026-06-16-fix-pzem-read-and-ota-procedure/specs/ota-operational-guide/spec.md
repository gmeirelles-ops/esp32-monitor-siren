## ADDED Requirements

### Requirement: Guia operacional OTA via MQTT documentado

O repositório SHALL conter procedimento passo a passo para atualizar firmware remotamente usando o comando `OTA_UPDATE` já existente.

#### Scenario: Operador executa OTA pela primeira vez

- **WHEN** segue o guia em `docs/GUIA_COMPLETO.md` (build → servir binário → MQTT → monitorar status)
- **THEN** consegue atualizar o ESP32 e confirmar nova `firmware_version` no heartbeat

### Requirement: Script auxiliar de OTA

O repositório SHALL incluir `scripts/serve_firmware_and_ota.sh` que serve o `.bin` via HTTP e publica `OTA_UPDATE` via `mosquitto_pub`.

#### Scenario: OTA com script

- **WHEN** operador define `BROKER`, `DEVICE_ID`, executa o script após `idf.py build`
- **THEN** o dispositivo recebe URL HTTP válida e publica eventos `tipo:ota` (`inicio`, `sucesso` ou `falha`)

## MODIFIED Requirements

### Requirement: Mapa GPIO documentado

A documentação SHALL refletir relé GPIO 4, botão GPIO 5, PZEM TX 27, RX 26.

#### Scenario: Consulta de ligação

- **WHEN** operador abre `GUIA_COMPLETO.md` seção de hardware
- **THEN** vê pinos 4/5/26/27 consistentes com `board_config.h`
