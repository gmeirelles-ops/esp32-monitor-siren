## MODIFIED Requirements

### Requirement: Conexão ao broker MQTT
O app SHALL conectar ao broker MQTT configurado nas Configurações, suportando transporte TLS (`mqtts`) e autenticação username/password quando configurados.

#### Scenario: Conexão TLS com broker configurado
- **WHEN** o operador configura host, porta TLS e CA nas Configurações
- **THEN** o app estabelece sessão MQTT cifrada e assina os tópicos `sirene/+/status`, `sirene/+/heartbeat`, `sirene/+/alerta`, `sirene/+/calibracao` e `sirene/+/presenca`

#### Scenario: Conexão legada sem TLS
- **WHEN** TLS não está habilitado nas Configurações
- **THEN** o app conecta via `mqtt://` como hoje, preservando compatibilidade com postos não migrados

#### Scenario: Credenciais MQTT configuradas
- **WHEN** username e password estão preenchidos nas Configurações
- **THEN** o app envia credenciais no CONNECT MQTT
