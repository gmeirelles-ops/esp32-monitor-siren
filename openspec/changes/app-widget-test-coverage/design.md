## Context

Padrão existente: `login_screen_test.dart` com `testWidgets`. `database.dart` suporta in-memory via construtor de teste.

## Goals / Non-Goals

**Goals:**
- Cobrir renderização e interações básicas (botões, empty states).
- Rodar em CI Linux sem Firebase.

**Non-Goals:**
- Golden tests visuais.
- E2E com broker MQTT real.

## Decisions

### 1. Test harness

**Decisão:** `test/helpers/app_test_harness.dart` com `pumpApp(Widget, overrides)`.

### 2. MQTT mock

**Decisão:** `ProviderScope` override de `mqttServiceProvider` com fake que não conecta.

### 3. Prioridade de telas

**Decisão:** Lote > Etiquetas > Painel > Configurações nesta ordem de implementação.

## Risks / Trade-offs

- **[Testes frágeis a layout]** → assert em keys semânticas (`Key('batch-send')`), não em texto longo.

## Migration Plan

1. Adicionar harness.
2. Uma tela por PR ou tarefa sequencial.

## Open Questions

- Adotar `integration_test` package depois?
