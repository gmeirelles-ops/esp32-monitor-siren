## Why

O app tem 55 testes unitários mas apenas `login_screen_test` cobre UI. Telas críticas — Lote, Etiquetas, Painel, Configurações — não têm widget tests; regressões de layout e fluxo operador passam despercebidas.

## What Changes

- Widget tests para `BatchScreen`, `LabelsScreen`, `DashboardScreen`, `SettingsScreen` (estados vazios e com dados mock).
- Helpers de teste: `ProviderScope` com overrides, banco Drift in-memory, MQTT mock.
- Integrar no CI (`add-ci-pipeline`).

## Capabilities

### New Capabilities

- `app-test-harness`: utilitários de teste Flutter compartilhados

### Modified Capabilities

- `flutter-app-shell`: cobertura de testes de widget nas telas principais

## Impact

- **App**: `test/` novos arquivos, possível `test/helpers/`
- Sem mudança de comportamento em produção
