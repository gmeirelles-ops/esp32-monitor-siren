## Why

O Painel já exporta PDF/XML e tem helper `formatDashboardSummaryCsv`, mas o gestor **não consegue escolher CSV** no diálogo nem salvar via seletor de arquivo. Qualidade/ERP pedem planilha (Excel PT-BR) com resumo e lista de testes do período filtrado.

## What Changes

- Incluir **CSV** no diálogo “Exportar relatório” do Painel (junto a PDF/XML).
- CSV resumo (métricas + throughput + falhas) e CSV **detalhado de testes** do período/filtros atuais.
- UTF-8 **com BOM** + separador `;` para Excel brasileiro.
- Salvar com `file_selector` (destino escolhido pelo usuário), reutilizando formatação existente onde fizer sentido.
- Testes unitários da formatação CSV (BOM, cabeçalhos, escaping).

## Capabilities

### New Capabilities

- `production-reporting`: exportação CSV de produção a partir do SQLite do posto

### Modified Capabilities

- `production-dashboard`: ação de exportação inclui CSV no Painel

## Impact

- `sirene_app/lib/features/dashboard/` — wire CSV + query de testes do período
- `sirene_app/lib/shared/reports/report_export_format.dart` — opção CSV
- `docs/PRODUCAO.md` — menção breve ao export CSV (opcional, 1 parágrafo)
- Sem firmware / Firestore
