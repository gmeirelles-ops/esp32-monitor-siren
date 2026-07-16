## Why

A change `app-db-sync-ux-polish` deixou de fora o `FutureBuilder` do histórico de calibração em `product_form_screen.dart` — ao concluir calibração MQTT, o histórico não atualiza até reabrir o formulário.

## What Changes

- Substituir `FutureBuilder` por stream Drift `watchCalibrationHistory(idProduto)`.
- Invalidar/atualizar ao receber evento `calibracao` MQTT para o produto em edição.
- Teste widget ou unitário do provider de histórico.

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `calibration-history`: histórico reativo no formulário de produto
- `product-catalog`: UX de edição de produto

## Impact

- **App**: `database.dart`, `product_form_screen.dart`, possivelmente `mqtt_providers.dart`
