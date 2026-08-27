## Why

`DevicesNotifier` em `mqtt_providers.dart` (~1100 linhas) concentra MQTT inbound, lote, seriais, MarkQueue, demo, OTA, calibração e ensaio. Isso dificulta testes, reviews e evolução (ex.: laser-only) sem regressão. Produto interno precisa de manutenção mais barata sem mudar o comportamento do posto.

## What Changes

- Extrair módulos coesos **sem alterar contratos públicos** (`devicesProvider`, `sendSetBatch`, `processTestResult`, streams).
- Sugestão de fatias:
  - inbound MQTT / FSM / heartbeat / rejeições
  - lote (SET/END, auto-end, reteste)
  - resultado de teste + serial + enfileiramento laser
  - comandos auxiliares (calibração, ensaio, OTA, RESET_WIFI)
- Manter `DevicesNotifier` como fachada fina ou mixin/part files.
- Testes existentes devem continuar verdes; acrescentar testes só se alguma fatia ganhar API testável pura.

## Capabilities

### New Capabilities

- _(nenhuma)_

### Modified Capabilities

- `mqtt-client`: organização interna do cliente/estado de dispositivos no app
- `flutter-app-shell`: sem mudança de UX; apenas estrutura de código

## Impact

- `sirene_app/lib/features/mqtt/` — split de arquivos
- Possível `features/batch/` ou `features/labels/` se marking migrar para helper
- **Não** muda firmware, MQTT wire format, UI de telas
