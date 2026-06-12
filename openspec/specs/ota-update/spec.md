# ota-update Specification

## Purpose
Atualização de firmware OTA no ESP32: download HTTP da imagem, validação e reboot com publicação de status de progresso via MQTT.
## Requirements
### Requirement: Atualização OTA disparada por MQTT
O dispositivo SHALL iniciar uma atualização de firmware ao receber o comando `OTA_UPDATE` com uma URL de imagem no payload, baixando e aplicando o binário via `esp_https_ota`.

#### Scenario: Comando OTA_UPDATE válido
- **WHEN** o dispositivo recebe no tópico de comando um JSON com `cmd: "OTA_UPDATE"` e um campo `url` válido
- **THEN** o dispositivo inicia o download do firmware a partir da URL e aplica a atualização

#### Scenario: OTA rejeitado durante teste
- **WHEN** um `OTA_UPDATE` chega enquanto o dispositivo está em `TESTING`
- **THEN** o dispositivo rejeita o comando, mantém o teste corrente e publica uma mensagem de rejeição

### Requirement: Validação de imagem e rollback
O dispositivo SHALL validar a imagem baixada antes de confirmá-la e SHALL reverter para a partição anterior caso a nova imagem falhe na inicialização.

#### Scenario: Imagem inválida
- **WHEN** a imagem baixada é corrompida ou falha na verificação
- **THEN** o dispositivo aborta a atualização, permanece na imagem atual e publica falha de OTA

#### Scenario: Rollback após boot malsucedido
- **WHEN** a nova imagem é aplicada mas não confirma a inicialização bem-sucedida
- **THEN** o dispositivo reverte automaticamente para a imagem anterior no próximo boot

### Requirement: Estado seguro durante OTA
O dispositivo SHALL garantir que o relé esteja desligado durante todo o processo de OTA.

#### Scenario: Relé desligado na atualização
- **WHEN** uma atualização OTA está em andamento
- **THEN** o relé permanece desligado e nenhum ciclo de teste é iniciado até a conclusão ou reinício

