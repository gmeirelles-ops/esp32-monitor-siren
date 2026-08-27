## Context

- `DashboardScreen._exportReport` usa `pickReportExportOptions` → só PDF/XML.
- `production_report_export.dart` já formata resumo CSV e salva em `Documents/relatorios` **sem** diálogo e **sem** BOM.
- Relatório de lote (`batch_report_export.dart`) já tem CSV detalhado + escaping `;` — reutilizar padrões.
- Filtros do painel (`DashboardFilters`: período, OP, produto, device) devem valer para o CSV.

## Goals / Non-Goals

**Goals**

- CSV no fluxo de export do Painel.
- Dois conteúdos: **resumo** e **testes** (escolha no diálogo ou dois botões CSV).
- Excel PT-BR: `;` + UTF-8 BOM.
- Destino via `getSaveLocation`.

**Non-Goals**

- Novo PDF (já existe).
- Export Firestore / e-mail / agendamento.
- Alterar layout do painel além do diálogo de export.

## Decisions

1. **Diálogo** — adicionar `ReportExportFormat.csv` e, ao escolher CSV, sub-escolha: “Resumo” | “Lista de testes” (ou dois botões no mesmo dialog).
2. **BOM** — prefixo `\uFEFF` no arquivo escrito.
3. **Query** — método Drift (ou reutilizar existente) listando `TestResult` no mesmo range/filtros do `dashboardDataProvider`.
4. **Decimal** — rendimento com `,` no CSV de resumo (`toStringAsFixed` + replace) para Excel PT; potências idem no detalhado.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Período “Tudo” gera CSV enorme | Aceitável no posto; documentar; sem paginação nesta change |

## Migration Plan

Nenhuma migração de schema.

## Open Questions

- _(nenhuma)_
