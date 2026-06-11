# wifi-provisioning Specification

## Purpose
Provisionamento Wi-Fi e broker MQTT via captive portal embarcado no ESP32.
## Requirements
### Requirement: Inicialização em modo SoftAP sem credenciais salvas
O dispositivo SHALL inicializar em modo SoftAP (Access Point) sempre que não houver credenciais de Wi-Fi válidas armazenadas na partição NVS.

#### Scenario: Primeira inicialização sem rede salva
- **WHEN** o dispositivo é ligado e a partição NVS não contém credenciais de Wi-Fi
- **THEN** o dispositivo cria um Access Point próprio e disponibiliza um servidor HTTP embarcado no IP `192.168.4.1`

#### Scenario: Credenciais salvas presentes
- **WHEN** o dispositivo é ligado e a NVS contém SSID e senha válidos
- **THEN** o dispositivo inicializa diretamente em modo Station (STA) sem subir o SoftAP

### Requirement: Coleta de credenciais via Captive Portal
O servidor HTTP embarcado SHALL fornecer uma interface HTML que colete SSID e senha e os persista na NVS.

#### Scenario: Operador envia credenciais válidas
- **WHEN** o operador conecta ao AP, acessa `192.168.4.1` e submete um SSID e senha pelo formulário
- **THEN** o dispositivo grava o SSID e a senha na partição NVS

#### Scenario: Reinício em modo Station após provisionamento
- **WHEN** as credenciais são gravadas com sucesso na NVS
- **THEN** o dispositivo reinicia e passa a operar em modo Station (STA) conectando-se à rede informada

### Requirement: Scan de redes no captive portal
O captive portal SHALL listar as redes Wi-Fi detectadas para que o operador selecione o SSID em vez de digitá-lo manualmente.

#### Scenario: Listagem de redes
- **WHEN** o operador acessa o captive portal em modo SoftAP
- **THEN** o portal apresenta a lista de SSIDs encontrados em um scan, com opção de inserir um SSID manualmente

### Requirement: Validação da conexão antes de persistir
O dispositivo SHALL validar as credenciais conectando em modo Station antes de gravá-las definitivamente na NVS, evitando salvar credenciais inválidas.

#### Scenario: Credenciais válidas
- **WHEN** o operador submete SSID e senha pelo portal
- **THEN** o dispositivo tenta conectar em STA e, ao obter sucesso, persiste as credenciais na NVS e prossegue

#### Scenario: Credenciais inválidas
- **WHEN** a tentativa de conexão STA com as credenciais informadas falha dentro do tempo limite
- **THEN** o dispositivo não persiste as credenciais e retorna ao portal com indicação de falha

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
