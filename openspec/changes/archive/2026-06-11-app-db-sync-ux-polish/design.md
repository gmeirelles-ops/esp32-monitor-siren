## Context

O SQLite local (schema v7) concentra testes, buffer de etiquetas e fila Firestore. Consultas analíticas (`productionSummary`, `throughputByDay`) já normalizam veredito com `toUpperCase() == 'APROVADO'`, mas `reconcileSerials` filtra com `veredito.equals('APROVADO')` — divergência que pode ocultar buracos/duplicatas se o firmware ou parser gravar variação de caixa.

`LabelsScreen` e `DashboardScreen` disparam `FutureBuilder` no build sem invalidação quando chegam novos resultados MQTT — o operador precisa trocar de aba ou período para ver dados atualizados.

A `SyncQueue` já persiste `attempts` e `last_error` e o processador para após 5 falhas, mas Configurações só mostra `Falhas permanentes: N` sem listagem nem retry — operador não consegue recuperar após correção de credencial/rede.

`ConnectionStatusBadge` está embutido só em `DevicesScreen`; nas demais telas o operador não vê queda do broker MQTT.

## Goals / Non-Goals

**Goals:**

- Consistência de veredito em todas as queries analíticas e de reconciliação.
- UI reativa via Drift streams ou Riverpod providers invalidados por eventos MQTT.
- Dead-letter visível e recuperável manualmente.
- Índices SQLite para consultas hot-path.
- Status MQTT sempre visível na shell.

**Non-Goals:**

- CI GitHub Actions (change separada `ci-pipeline`).
- Segurança firmware MQTT TLS (change separada).
- Atualização de `docs/PRODUCAO.md` além de nota breve se necessário.
- Retry automático infinito ou alteração do limite de 5 tentativas.
- Refatorar todas as telas que usam `FutureBuilder` (ex.: histórico de calibração em produto).

## Decisions

### 1. Veredito aprovado: helper compartilhado

**Decisão:** extrair `isApprovedVeredito(String veredito)` em módulo puro (ou método estático em `database.dart`) usando `veredito.trim().toUpperCase() == 'APROVADO'`. Usar em `reconcileSerials`, e opcionalmente refatorar `productionSummary` para o mesmo helper.

**Alternativa:** filtrar em memória após query sem `veredito` — mais I/O, descartada.

### 2. Reatividade: Drift `watch` + providers

**Decisão:**

- `watchLabelBuffer()` e `watchLabelBufferCount()` como streams Drift.
- `dashboardDataProvider` como `FutureProvider`/`AsyncNotifier` parametrizado por período, invalidado via `ref.invalidate` no pipeline MQTT após `insertTestResult` (ou `ref.listen` a um `testResultsRevisionProvider` incrementado).

**Alternativa:** `Timer.periodic` polling — desperdício e latência.

### 3. Dead-letter UI em Configurações

**Decisão:** seção "Fila com falha" abaixo do status atual quando `failed > 0`:

- `getFailedSyncItems()` retorna entradas com `attempts >= 5`.
- Botão por item ou global "Reprocessar falhas" chama `resetSyncAttempts(id)` (zera attempts/lastError) + `processQueue()`.

**Alternativa:** tela Admin separada — mais cliques; Configurações já concentra sync.

### 4. Índices SQLite (schema v8)

**Decisão:** migration v8 com:

```sql
CREATE INDEX IF NOT EXISTS idx_test_results_serial ON test_results(serial);
CREATE INDEX IF NOT EXISTS idx_test_results_created_at ON test_results(created_at);
CREATE INDEX IF NOT EXISTS idx_sync_queue_attempts ON sync_queue(attempts);
```

**Alternativa:** índices compostos — desnecessário no volume atual do posto.

### 5. ConnectionStatusBadge global

**Decisão:** mover badge para `DipontoAppBar.actions` (desktop e mobile), removendo duplicata em `DevicesScreen`.

## Risks / Trade-offs

- **[Invalidação excessiva do painel]** → invalidar só após insert de teste/falha HW, não a cada heartbeat.
- **[Reset manual reenvia payload obsoleto]** → aceitável; Firestore upsert é idempotente por design.
- **[Migration v8 em postos existentes]** → índices são online-safe; sem perda de dados.

## Migration Plan

1. Deploy app Windows; Drift aplica migration v8 no primeiro boot.
2. Operadores com falhas permanentes usam "Reprocessar" após corrigir Firebase/rede.
3. Validar reconciliação e painel reativo com teste MQTT ao vivo.

## Open Questions

- Nenhuma bloqueante. Texto do botão de retry: "Tentar novamente" vs "Reprocessar fila".
