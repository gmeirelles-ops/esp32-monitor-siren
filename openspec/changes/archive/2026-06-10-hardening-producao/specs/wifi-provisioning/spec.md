## ADDED Requirements

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
