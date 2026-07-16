## MODIFIED Requirements

### Requirement: Lista de dispositivos descobertos
O app SHALL manter descoberta automática de dispositivos via MQTT e SHALL expor a lista completa com detalhe técnico em área secundária (Configurações → Dispositivos), enquanto a seleção de bancada para lote permanece na tela Lote.

#### Scenario: Novo dispositivo detectado
- **WHEN** o app recebe a primeira mensagem de `sirene/<device_id>/heartbeat`
- **THEN** o dispositivo é adicionado ao estado interno e fica disponível no dropdown da tela Lote e na lista em Configurações → Dispositivos

#### Scenario: Dispositivo offline
- **WHEN** o app recebe `offline` em `sirene/<device_id>/presenca` (LWT)
- **THEN** o dispositivo é marcado como offline na lista secundária e no indicador do dropdown de Lote

#### Scenario: Detalhe técnico do dispositivo
- **WHEN** o supervisor abre Configurações → Dispositivos e seleciona um item
- **THEN** o app exibe estado FSM, RSSI, uptime, fila offline e versão de firmware como hoje na tela de detalhe
