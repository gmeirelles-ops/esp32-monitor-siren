## ADDED Requirements

### Requirement: Servidor HTTP embutido para OTA

O app Flutter SHALL iniciar um servidor HTTP local que sirva o arquivo `.bin` selecionado, com URL acessível na LAN do posto.

#### Scenario: Servidor inicia com arquivo válido

- **WHEN** o operador seleciona `sirene-validator.bin` e confirma OTA
- **THEN** o app expõe o arquivo em `http://<ip_lan>:<porta>/sirene-validator.bin` e valida resposta HTTP 200 localmente antes de enviar MQTT

#### Scenario: Porta ocupada

- **WHEN** a porta configurada já está em uso
- **THEN** o app exibe erro claro e não envia `OTA_UPDATE`

### Requirement: OTA MQTT one-click

O app SHALL publicar `OTA_UPDATE` com URL gerada automaticamente e monitorar eventos `tipo:ota` no tópico `status`.

#### Scenario: OTA bem-sucedido

- **WHEN** o ESP32 conclui download e reinicia
- **THEN** a UI mostra `evento: sucesso` e nova `firmware_version` no heartbeat do dispositivo alvo

#### Scenario: Device offline

- **WHEN** o dispositivo alvo não está `online`
- **THEN** o app bloqueia o envio e exibe mensagem explicativa

#### Scenario: Teste em andamento

- **WHEN** estado FSM é `TESTING`
- **THEN** o app bloqueia OTA e informa que deve aguardar fim do teste
