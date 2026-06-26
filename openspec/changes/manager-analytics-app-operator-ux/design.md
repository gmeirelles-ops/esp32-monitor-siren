## Context

```
Hoje:
  sirene_app (operador)
    ├─ Lote → SET_BATCH ("Configurar lote")
    ├─ Painel → SQLite local, gráficos completos
    ├─ AppBar → ConnectionStatusBadge (StreamProvider → null = Desconectado)
    └─ Sync → Firestore test_results / operators / products

Mock gestor:
  KPIs + trends, gráficos 7d, tabela lotes com status, sem Ações
```

O operador precisa de fluxo rápido (INICIAR). O gestor precisa de visão consolidada multi-posto via nuvem.

## Goals / Non-Goals

**Goals:**

- App gestor com UI do mock, dados Firestore
- Operador: INICIAR + badge MQTT correto + menos distração no menu
- Tabela gestor sem coluna Ações

**Non-Goals:**

- Gestor controlar bancadas ou enviar SET_BATCH
- Reimplementar sync no gestor (reusa dados já enviados pelos postos)

## Decisions

### 1. Dois apps, um backend

| App | Público | Dados | MQTT |
|-----|---------|-------|------|
| `sirene_app` | Operador | SQLite + sync out | Sim |
| `sirene_manager_app` | Gestor | Firestore read | Não |

Monorepo: `sirene_manager_app/` ao lado de `sirene_app/`, compartilhar `firebase_options` / tema via pacote `sirene_ui` opcional (fase 2).

### 2. Correção badge "Desconectado"

Problema: `mqttConnectionStateProvider` é `StreamProvider`; enquanto `AsyncLoading`, `.value` é `null` → fallback `disconnected`.

```dart
final mqttAsync = ref.watch(mqttConnectionStateProvider);
final state = mqttAsync.when(
  data: (s) => s,
  loading: () => ref.read(mqttServiceProvider).currentState,
  error: (_, __) => AppMqttConnectionState.disconnected,
);
```

Alternativa: `StreamProvider` com `initialValue: service.currentState` via custom provider.

### 3. Botão INICIAR

- Texto: **INICIAR** (sem sufixo SET_BATCH)
- Mantém mesma ação: validar form → `resolveBatchYear` / `resolveProximoSequencial` → `sendSetBatch` → `BatchLiveScreen`
- Spec `batch-operator-ui` atualiza cenário de rótulo

### 4. Painel no app operador

**Decisão:** remover item **Painel** da `NavigationRail` e substituir por card opcional na tela Lote ("Hoje: N testes") **ou** manter Painel ultra-minimal (só contadores do dia, sem gráficos).

Gestor recebe 100% do mock analítico.

### 5. App gestor — arquitetura

```
sirene_manager_app
  ├─ LoginScreen (Firebase Auth)
  ├─ ManagerShell
  │    └─ AnalyticsDashboardScreen
  │         ├─ PeriodFilters + OP/Produto/Bancada
  │         ├─ KpiRow (Firestore aggregates)
  │         ├─ ThroughputChart (7d stacked)
  │         ├─ YieldLineChart (meta 70% configurável)
  │         └─ BatchTable (sem Ações)
  └─ firestore_analytics_repository.dart
```

**Fonte de dados v1:** queries Firestore client-side com índices compostos em `test_results` (filtrar por `station_id`, `timestamp`, `numero_op`). Se volume crescer, Cloud Function `aggregateDailyMetrics`.

**Status do lote na tabela:**

| Condição | Status |
|----------|--------|
| OP com testes recentes (< 2h) e meta não atingida | Em andamento |
| yield < meta configurada | Revisar |
| meta atingida ou OP encerrada localmente | Concluído |

Derivado de campos syncados + heurística de tempo (documentar em spec).

### 6. Autenticação gestor

- Mesmo projeto Firebase
- Custom claim `role: manager` **ou** coleção `managers/{uid}` para rules
- Rules: gestor `read` em `test_results`, `operators`, `products`; operador posto mantém write apenas do próprio `station_id`

### 7. Gráficos

Reutilizar padrão visual do mock (barras empilhadas amber/verde, linha rendimento). Pacote: `fl_chart` ou evoluir `SimpleBarChart` existente em pacote compartilhado.

KPI trends ("+20% vs ontem"): comparar agregado período atual vs período anterior de mesma duração.

## Risks / Trade-offs

- **[Gestor offline]** — sem Firestore, gestor não funciona; aceito (supervisor usa rede escritório)
- **[Sync atrasado]** — métricas gestor dependem de sync habilitado nos postos; card de aviso se `last_sync` antigo
- **[Duplicação UI]** — dois apps para manter; mitigar tema/widgets compartilhados depois

## Migration Plan

1. Ship correções operador (INICIAR + badge) — patch rápido
2. Remover/simplificar Painel operador
3. Scaffold `sirene_manager_app` + login + dashboard v1
4. Ajustar Firestore rules para leitura gestor
5. Documentar em `PRODUCAO.md`: operador vs gestor

## Open Questions

- Meta de rendimento fixa 70% ou configurável no gestor? **Proposta:** 70% default, campo em Config do gestor v1.1
- Gestor vê todos os postos ou só `station_id` atribuído? **Proposta:** todos os postos com sync; filtro por bancada/station na UI
