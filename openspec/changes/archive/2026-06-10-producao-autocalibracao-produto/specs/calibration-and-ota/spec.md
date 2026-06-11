## MODIFIED Requirements

### Requirement: Modo calibração
O app SHALL permitir autocalibração exclusivamente na tela de cadastro de produtos, enviando `START_CALIBRATION` quando o dispositivo selecionado estiver em estado `IDLE`.

#### Scenario: Calibração iniciada no cadastro
- **WHEN** o operador aciona "Medir peça padrão" na tela de cadastro de produto e o heartbeat indica `estado: "IDLE"`
- **THEN** o app envia `{"cmd": "START_CALIBRATION"}`, exibe indicador de medição em andamento e painel de leituras ao vivo

#### Scenario: Resultado de calibração exibido no cadastro
- **WHEN** o app recebe mensagem em `sirene/<device_id>/calibracao` com `tipo: "calibracao"` e `potencia_media`
- **THEN** o app preenche `potencia_ref` e calcula `potencia_min`/`potencia_max` para confirmação no cadastro do produto

#### Scenario: Calibração rejeitada
- **WHEN** o dispositivo não está em `IDLE` e o operador tenta calibrar no cadastro
- **THEN** o app exibe a rejeição recebida (`calibracao_estado_invalido`) e não envia o comando

### Requirement: Restrição de acesso admin
O app SHALL restringir a tela Admin exclusivamente à atualização OTA remota.

#### Scenario: Operador acessa admin
- **WHEN** o operador navega para a seção Admin
- **THEN** apenas as opções de OTA estão disponíveis
