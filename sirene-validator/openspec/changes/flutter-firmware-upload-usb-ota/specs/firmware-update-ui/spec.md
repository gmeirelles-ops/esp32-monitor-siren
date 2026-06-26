## ADDED Requirements

### Requirement: Tela unificada de atualização de firmware

O app SHALL oferecer tela com abas **Pela rede (OTA)** e **Por USB (cabo)** acessível a partir de Configurações e do detalhe da bancada.

#### Scenario: Acesso a partir da bancada

- **WHEN** operador abre detalhe de um dispositivo e toca "Atualizar firmware"
- **THEN** a tela abre com `device_id` pré-selecionado na aba OTA

#### Scenario: Fluxo OTA em 3 passos

- **WHEN** operador segue: escolher arquivo → escolher dispositivo → Iniciar
- **THEN** não é necessário MQTT Explorer nem terminal externo

### Requirement: Feedback de progresso

A tela SHALL exibir estados `preparando`, `enviando`, `aguardando reinício` e resultado final com versão de firmware.

#### Scenario: Sucesso OTA

- **WHEN** heartbeat reporta versão diferente da anterior após OTA
- **THEN** UI exibe confirmação verde com número da versão

## MODIFIED Requirements

### Requirement: AdminScreen integrado ao fluxo assistido

A campanha OTA em `AdminScreen` SHALL usar o serviço de OTA assistido em vez de exigir URL digitada manualmente como fluxo principal.

#### Scenario: Campanha multi-device

- **WHEN** administrador seleciona vários dispositivos e um `.bin`
- **THEN** o app serve o arquivo uma vez e envia `OTA_UPDATE` para cada `device_id` selecionado
