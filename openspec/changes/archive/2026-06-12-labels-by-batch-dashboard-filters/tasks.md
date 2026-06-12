## 1. Database e providers

- [x] 1.1 Criar `DashboardFilters` e `dashboardFiltersProvider` (período + OP + produto + dispositivo)
- [x] 1.2 Estender `productionSummary`, `throughputByDay`, `hardwareFaultCounts` com filtros opcionais
- [x] 1.3 Adicionar `batchSummaryInPeriod` e queries `distinctOps` / `distinctProducts` / `distinctDevices`
- [x] 1.4 Corrigir `throughputByDay` para respeitar o período selecionado (não fixo em 7 dias)
- [x] 1.5 Helper `groupLabelBufferByOp(List<LabelBufferEntry>)` para agrupamento ordenado

## 2. Painel — filtros e métricas

- [x] 2.1 UI de filtros: período + dropdowns OP, produto, dispositivo com opção "Todos"
- [x] 2.2 Atualizar `dashboardDataProvider` para usar `DashboardFilters`
- [x] 2.3 Empty state quando filtros não retornam dados

## 3. Painel — gráficos

- [x] 3.1 Refatorar gráfico de throughput para `SimpleBarChart` com legenda aprovado/total
- [x] 3.2 Adicionar gráfico de yield % por dia
- [x] 3.3 Seção "Produção por lote" (tabela ou barras) quando OP não está filtrada
- [x] 3.4 Legenda e rótulos de data consistentes com tema Diponto

## 4. Etiquetas agrupadas por lote

- [x] 4.1 Substituir lista plana por `ExpansionTile` por OP com contagem e aviso de órfãs
- [x] 4.2 Sublista de seriais dentro de cada grupo (serial + timestamp)
- [x] 4.3 Botão "Imprimir lote" por grupo reutilizando `printLabelBatches`
- [x] 4.4 Manter botão global "Imprimir pendentes" e badge reativo

## 5. Testes e validação

- [x] 5.1 Testes unitários: `groupLabelBufferByOp`, queries filtradas, `batchSummaryInPeriod`
- [x] 5.2 Testes: throughput respeita período; yield por dia calculado corretamente
- [x] 5.3 Rodar `flutter test` completo
