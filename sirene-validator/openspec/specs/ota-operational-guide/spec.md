## ADDED Requirements

### Requirement: App Flutter como método principal de OTA

O app Flutter Windows SHALL oferecer fluxo OTA assistido que serve o `.bin` via HTTP embutido e publica `OTA_UPDATE` sem ferramentas externas.

#### Scenario: Operador atualiza pela rede

- **WHEN** usa Configurações → Atualizar firmware → aba OTA
- **THEN** consegue selecionar `.bin`, bancada e iniciar OTA com feedback de progresso

### Requirement: App Flutter gravação USB

O app Flutter Windows SHALL oferecer gravação USB via esptool (empacotado ou Python) na mesma tela de firmware.

#### Scenario: Atualizar app por cabo

- **WHEN** operador seleciona porta COM e modo "Atualizar app"
- **THEN** esptool grava `sirene-validator.bin` em `0x20000`

## MODIFIED Requirements

### Requirement: Guia operacional OTA via MQTT documentado

O repositório SHALL documentar o app Flutter como método principal, mantendo MQTT Explorer e scripts como alternativas avançadas.

#### Scenario: Documentação atualizada

- **WHEN** operador consulta `docs/GUIA_COMPLETO.md` §11
- **THEN** encontra fluxo app OTA/USB antes das instruções manuais
