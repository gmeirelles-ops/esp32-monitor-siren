## ADDED Requirements

### Requirement: Campanha de OTA para múltiplos dispositivos
O app SHALL permitir selecionar vários dispositivos e enviar o mesmo `OTA_UPDATE` (URL de firmware) para todos em uma única ação.

#### Scenario: OTA enviado para seleção
- **WHEN** o operador seleciona dois ou mais dispositivos, informa a URL do firmware e confirma a campanha
- **THEN** o app publica `OTA_UPDATE` com a URL para cada dispositivo selecionado

#### Scenario: Acompanhamento por dispositivo
- **WHEN** os dispositivos publicam eventos de status de OTA
- **THEN** o app exibe o status recebido associando-o ao respectivo dispositivo

#### Scenario: Nenhum dispositivo selecionado
- **WHEN** o operador tenta enviar a campanha sem selecionar dispositivos ou sem URL
- **THEN** o app não envia comando e orienta a completar a seleção
