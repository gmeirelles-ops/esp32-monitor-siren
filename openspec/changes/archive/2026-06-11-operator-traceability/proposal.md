## Why

Hoje um resultado de teste registra device, OP, veredito, potência, sequencial e serial — mas não **quem** operava a bancada. Para auditoria de qualidade (e responsabilização em recall), é essencial saber qual operador validou cada peça. O app já tem login Firebase Auth; basta carimbar a identidade do operador autenticado em cada resultado.

## What Changes

- Gravar o identificador do operador (e-mail da conta autenticada) em cada `test_results`, local (SQLite) e na nuvem (Firestore).
- Quando não houver operador autenticado (ex.: Linux sem Firebase, ou sync desligado), gravar `null`/ausente sem bloquear o fluxo.
- Exibir o operador no card de último resultado da tela de Lote.

## Capabilities

### New Capabilities

- `operator-traceability`: Captura e persistência da identidade do operador em cada resultado de teste.

### Modified Capabilities

- `firestore-sync`: O payload de `test_results` passa a incluir `operador`.
- `device-monitoring`: O histórico local de testes passa a registrar o operador.

## Impact

- **App Flutter** (`sirene_app/`): coluna `operador` em `TestResults` (schema v5, migração addColumn), `insertTestResult` e `enqueueTestResult` recebem operador, `mapTestResult` inclui `operador`, captura via `authServiceProvider` em `mqtt_providers.dart`, exibição em `batch_screen.dart`.
- **Firmware ESP32**: nenhuma alteração.
- **Firestore**: campo adicional `operador` em `test_results` (aditivo, sem mudança de regras).
