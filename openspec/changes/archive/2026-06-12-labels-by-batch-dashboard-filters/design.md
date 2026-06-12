## Context

A tela **Etiquetas** (`labels_screen.dart`) lista o buffer em ordem cronológica plana (`watchLabelBuffer`). Cada entrada já possui `numero_op`, mas a UI não agrupa. Com 4 seriais de uma OP e 2 de outra, o operador não distingue facilmente os lotes nem imprime só um deles.

O **Painel** (`dashboard_screen.dart`) filtra apenas por `DashboardPeriod` (hoje / 7 dias / tudo). As queries em `database.dart` (`productionSummary`, `throughputByDay`, `hardwareFaultCounts`) aceitam `since` mas não OP, produto ou dispositivo. Os gráficos são barras simples inline (`_BarChart`) sem legenda de aprovado/reprovado nem gráfico de yield.

## Goals / Non-Goals

**Goals:**

- Etiquetas organizadas por OP (lote), expansível, com contagem e lista de seriais dentro de cada grupo
- Impressão manual por lote (subset do buffer da OP) além da impressão global existente
- Painel com filtros combináveis: período + OP + produto + dispositivo
- Gráficos mais legíveis: throughput com legenda aprovado/total, yield % por dia, resumo por lote no período
- Reutilizar `SimpleBarChart` onde possível para consistência visual

**Non-Goals:**

- Alterar regra de múltiplos de 3 ou lógica ZPL
- Histórico de etiquetas já impressas (só buffer pendente)
- Exportação CSV/PDF do painel
- Filtros por operador (pode ser fase futura)
- Nova dependência de charting (fl_chart, etc.)

## Decisions

### 1. Agrupamento de etiquetas em memória

**Decisão:** Agrupar `List<LabelBufferEntry>` por `numeroOp` no provider/widget, ordenando OPs pela etiqueta mais antiga de cada grupo.

**Alternativa:** Query SQL `GROUP BY numero_op` — desnecessário; o buffer é pequeno (<100 entradas típicas).

### 2. UI de grupos expansíveis

**Decisão:** `ExpansionTile` por OP com cabeçalho mostrando OP, quantidade de etiquetas e chip de órfãs (`count % 3`). Sublista com `ListTile` por serial (como hoje).

**Alternativa:** Tabs por OP — ruim quando há muitos lotes simultâneos.

### 3. Impressão por lote

**Decisão:** Botão "Imprimir lote" em cada `ExpansionTile`, reutilizando `printLabelBatches` apenas com entradas da OP. Botão global "Imprimir todas" permanece no rodapé.

**Alternativa:** Só impressão global — não atende operação por lote.

### 4. Modelo de filtros do painel

**Decisão:** Classe imutável `DashboardFilters` com `period`, `numeroOp?`, `idProduto?`, `deviceId?`. `StateProvider<DashboardFilters>` substitui `dashboardPeriodProvider` (ou o envolve).

Filtros de OP/produto/dispositivo populados a partir de valores distintos no SQLite (`distinctOps`, `distinctProducts`, `distinctDevices`).

### 5. Queries filtradas no SQLite

**Decisão:** Estender `productionSummary`, `throughputByDay`, `hardwareFaultCounts` com parâmetros opcionais `numeroOp`, `idProduto`, `deviceId`. Nova query `batchSummaryInPeriod` retorna lista de `(numeroOp, total, aprovados, reprovados, yield)` para gráfico/tabela por lote.

### 6. Gráficos aprimorados

**Decisão:**
- Extrair/mover `_BarChart` para `SimpleBarChart` compartilhado (já existe em batch live) com suporte a legenda e cores secundárias
- Adicionar gráfico de linha ou barras de yield % por dia (7 dias, respeitando filtros)
- Tabela ou barras horizontais "Produção por lote" quando filtro de OP não está fixo

**Alternativa:** fl_chart — rejeitado para manter zero dependências.

### 7. Throughput alinhado ao período

**Decisão:** `throughputByDay` passa a respeitar o período selecionado (hoje = 1 dia, semana = 7, tudo = últimos 30 dias ou todos os dias com dados).

Hoje o throughput ignora o filtro de período — corrigir como parte desta change.

## Risks / Trade-offs

- **[Risco] Muitos lotes no buffer** → ExpansionTiles longos; mitigar com ordenação por data e scroll
- **[Risco] Filtros sem dados** → Empty state específico "Nenhum teste com estes filtros"
- **[Trade-off] Impressão por lote com órfãs** → Mesma regra de múltiplo de 3 dentro do subset; aviso por grupo
- **[Trade-off] Performance com histórico grande** → Índices existentes em `test_results`; queries com WHERE são aceitáveis offline

## Migration Plan

1. Adicionar queries e `DashboardFilters` no database/providers
2. Refatorar painel com filtros e gráficos
3. Refatorar etiquetas com agrupamento
4. Testes unitários de agrupamento e queries filtradas
5. Sem migração de schema — apenas UI e queries

Rollback: reverter telas; dados intactos.

## Open Questions

- Ordenar lotes no painel por yield ou por volume? → **Volume (total testado) decrescente**
- Lote sem OP no buffer (edge case)? → Agrupar em "Sem OP" se `numeroOp` vazio
