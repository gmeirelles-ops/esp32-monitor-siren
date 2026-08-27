## ADDED Requirements

### Requirement: Assistente OTA no posto
O fluxo operacional de atualização OTA SHALL poder ser concluído pelo app (seleção do `.bin`, serve HTTP, `OTA_UPDATE`) sem exigir `python -m http.server` digitado no terminal.

#### Scenario: Atualização de bancada online
- **WHEN** o gestor escolhe `.bin` e inicia OTA na UI
- **THEN** o dispositivo recebe URL HTTP alcançável na LAN (salvo bloqueio de firewall externo ao app)
