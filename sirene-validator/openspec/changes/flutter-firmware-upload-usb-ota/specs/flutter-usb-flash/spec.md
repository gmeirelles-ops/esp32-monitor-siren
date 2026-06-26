## ADDED Requirements

### Requirement: Listagem de portas COM no Windows

O app Flutter (Windows) SHALL listar portas seriais disponíveis para seleção antes da gravação USB.

#### Scenario: ESP32 conectado

- **WHEN** o cabo USB está plugado e driver instalado
- **THEN** a porta COM correspondente aparece na lista

#### Scenario: Nenhuma porta

- **WHEN** não há portas seriais
- **THEN** a UI orienta verificar cabo e driver CP210x/CH340

### Requirement: Gravação via esptool empacotado

O app SHALL executar `esptool.exe` empacotado sem exigir Python ou ESP-IDF no PC do operador.

#### Scenario: Atualizar apenas app

- **WHEN** operador escolhe modo "Atualizar app" e `.bin` válido
- **THEN** esptool grava `sirene-validator.bin` no offset `0x20000` e a UI exibe log até conclusão

#### Scenario: Flash completo

- **WHEN** operador escolhe modo "Flash completo" e seleciona diretório `build/` com os 4 binários
- **THEN** esptool grava bootloader, partition table, ota_data e app nos offsets documentados

#### Scenario: Falha de gravação

- **WHEN** esptool retorna código de erro
- **THEN** a UI exibe stderr e mantém estado `failed` sem reiniciar fluxo de produção
