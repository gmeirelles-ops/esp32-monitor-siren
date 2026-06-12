## ADDED Requirements

### Requirement: Modo calibração
O app SHALL permitir enviar `START_CALIBRATION` quando o dispositivo estiver em estado `IDLE`.

#### Scenario: Calibração iniciada
- **WHEN** o operador aciona "Iniciar calibração" e o heartbeat indica `estado: "IDLE"`
- **THEN** o app envia `{"cmd": "START_CALIBRATION"}` e exibe indicador de medição em andamento

#### Scenario: Resultado de calibração exibido
- **WHEN** o app recebe mensagem em `sirene/<device_id>/calibracao` com potencia_media
- **THEN** o app exibe a potência média de referência para cadastro de produto

#### Scenario: Calibração rejeitada
- **WHEN** o dispositivo não está em `IDLE` e o operador tenta calibrar
- **THEN** o app exibe a rejeição recebida (`calibracao_estado_invalido`) e não envia o comando

### Requirement: Atualização OTA remota
O app SHALL permitir enviar `OTA_UPDATE` com URL do binário de firmware para administradores.

#### Scenario: OTA iniciada
- **WHEN** o administrador informa URL válida e confirma atualização
- **THEN** o app envia `{"cmd": "OTA_UPDATE", "url": "<url>"}` e monitora mensagens `tipo: "ota"` em status

#### Scenario: OTA concluída com sucesso
- **WHEN** chega `{"tipo": "ota", "evento": "sucesso"}`
- **THEN** o app exibe confirmação e aguarda reconexão do dispositivo com nova firmware_version

#### Scenario: OTA falhou
- **WHEN** chega `{"tipo": "ota", "evento": "falha"}`
- **THEN** o app exibe erro com detalhe e mantém versão anterior visível

### Requirement: Restrição de acesso admin
O app SHALL restringir telas de calibração e OTA à seção Admin.

#### Scenario: Operador acessa admin
- **WHEN** o operador navega para a seção Admin
- **THEN** as opções de calibração e OTA estão disponíveis
