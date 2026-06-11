## ADDED Requirements

### Requirement: Coleta de broker MQTT via Captive Portal
O servidor HTTP embarcado SHALL fornecer campos opcionais para host e porta do broker MQTT e SHALL persisti-los na NVS junto com as credenciais Wi-Fi.

#### Scenario: Operador informa broker no provisionamento
- **WHEN** o operador submete SSID, senha, host MQTT e porta pelo formulário do portal
- **THEN** o dispositivo grava host e porta no namespace NVS `mqtt_cfg` antes de reiniciar em modo Station

#### Scenario: Operador omite broker no provisionamento
- **WHEN** o operador submete apenas SSID e senha deixando os campos de broker vazios
- **THEN** o dispositivo não grava `mqtt_cfg` e utiliza o fallback definido em `board_config.h` após o boot

#### Scenario: Re-provisionamento altera broker
- **WHEN** o operador acessa novamente o portal e altera host/porta do broker
- **THEN** o dispositivo sobrescreve `mqtt_cfg` e reconecta ao novo broker após reinício
