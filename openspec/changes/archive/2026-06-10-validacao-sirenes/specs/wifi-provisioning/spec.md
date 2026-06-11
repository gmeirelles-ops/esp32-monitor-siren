## ADDED Requirements

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
