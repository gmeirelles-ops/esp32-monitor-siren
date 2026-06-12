## Why

Com múltiplos lotes em produção, a tela de Etiquetas exibe uma lista plana de seriais pendentes — difícil saber quantas etiquetas pertencem a cada OP e imprimir por lote. O Painel de produção oferece apenas filtro por período (Hoje / 7 dias / Tudo) e gráficos básicos, insuficientes para o supervisor analisar yield por lote, produto ou tendência com mais clareza.

## What Changes

- **Etiquetas agrupadas por lote (OP):** reorganizar a tela em seções expansíveis por `numero_op`, cada uma listando as etiquetas pendentes daquele lote, com contagem e ação de impressão por lote ou global.
- **Painel — filtros avançados:** adicionar filtro por OP (lote), produto (`id_produto`) e dispositivo, combináveis com o período existente.
- **Painel — gráficos aprimorados:** melhorar legibilidade dos gráficos (rótulos, cores aprovado/reprovado, eixos), adicionar gráfico de yield por dia e visão resumida por lote no período filtrado.
- Manter regras atuais de impressão (múltiplos de 3, fechamento manual, reimpressão) sem alteração de comportamento de buffer.

## Capabilities

### New Capabilities

_(nenhuma — extensões ficam nas specs existentes)_

### Modified Capabilities

- `label-printing`: agrupamento visual do buffer por OP com sublista de etiquetas e impressão contextual por lote
- `production-dashboard`: filtros por OP, produto e dispositivo; gráficos aprimorados e métricas por lote no período

## Impact

- `lib/features/labels/labels_screen.dart` — UI agrupada por OP
- `lib/features/dashboard/dashboard_screen.dart`, `dashboard_providers.dart` — novos filtros e queries
- `lib/core/database/database.dart` — consultas filtradas por OP/produto/dispositivo; agrupamento do buffer por OP
- `lib/shared/widgets/simple_bar_chart.dart` — reutilizar ou estender para gráficos do painel
- Testes: `dashboard_metrics_test.dart`, novos testes de agrupamento de etiquetas
