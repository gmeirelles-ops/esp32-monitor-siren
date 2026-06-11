## MODIFIED Requirements

### Requirement: Broker MQTT configurado em tempo de compilação
O endereço do broker MQTT SHALL ser resolvido em tempo de execução a partir da NVS (`mqtt_cfg`), utilizando o valor definido via `#define` em `board_config.h` apenas como fallback quando não houver configuração persistida.

#### Scenario: Conexão com broker da NVS
- **WHEN** o dispositivo está em modo Station, possui `mqtt_cfg` válido na NVS e a rede está disponível
- **THEN** o dispositivo conecta ao broker MQTT cujo host e porta foram lidos da NVS

#### Scenario: Conexão com fallback de compilação
- **WHEN** o dispositivo está em modo Station, não possui `mqtt_cfg` na NVS e a rede está disponível
- **THEN** o dispositivo conecta ao broker definido por `MQTT_BROKER_URI` em `board_config.h`

#### Scenario: URI montada corretamente
- **WHEN** a NVS contém host `192.168.51.87` e porta `1883`
- **THEN** o cliente MQTT utiliza a URI `mqtt://192.168.51.87:1883`
