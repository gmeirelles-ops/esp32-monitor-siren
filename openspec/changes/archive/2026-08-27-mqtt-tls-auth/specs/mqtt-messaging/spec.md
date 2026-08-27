## MODIFIED Requirements

### Requirement: Broker MQTT configurável via NVS
O endereço do broker MQTT SHALL ser resolvido em tempo de execução a partir da NVS (`mqtt_cfg`), utilizando o valor definido via `#define` em `board_config.h` apenas como fallback quando não houver configuração persistida. A configuração NVS SHALL suportar URI `mqtts://` com CA e credenciais username/password opcionais.

#### Scenario: Conexão com broker da NVS
- **WHEN** o dispositivo está em modo Station, possui `mqtt_cfg` válido na NVS e a rede está disponível
- **THEN** o dispositivo conecta ao broker MQTT cujo host, porta, TLS e credenciais foram lidos da NVS

#### Scenario: Conexão com fallback de compilação
- **WHEN** o dispositivo está em modo Station, não possui `mqtt_cfg` na NVS e a rede está disponível
- **THEN** o dispositivo conecta ao broker definido por `MQTT_BROKER_URI` em `board_config.h`

#### Scenario: URI montada corretamente
- **WHEN** a NVS contém host `192.168.51.87`, porta `8883` e TLS habilitado
- **THEN** o cliente MQTT utiliza a URI `mqtts://192.168.51.87:8883` com verificação de certificado

#### Scenario: Credenciais inválidas
- **WHEN** username ou password na NVS estão incorretos para o broker
- **THEN** o dispositivo falha na conexão, aplica backoff de reconexão e não bloqueia testes locais por botão físico
