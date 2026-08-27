## Context

`dashboard_providers.dart` já agrega `productionSummary`, `throughputByDay`, `hardwareFaultCounts` e alertas recentes via SQLite.

Windows desktop suporta `file_selector` / salvar via diálogo nativo.

## Goals / Non-Goals

**Goals:**
- CSV UTF-8 com BOM para Excel brasileiro.
- Exportar exatamente o período visível no Painel (Hoje / 7 dias / Tudo).

**Non-Goals:**
- PDF nesta change.
- Relatórios agendados ou envio por e-mail.
- Exportação direto do Firestore (dados locais são fonte da verdade no posto).

## Decisions

### 1. Formato CSV

**Decisão:** separador `;` e decimal `,` para compatibilidade Excel PT-BR; cabeçalho na primeira linha.

### 2. Três arquivos ou um ZIP

**Decisão:** um CSV por tipo com sufixo de data (`producao_2026-06-12.csv`, `testes_...`, `falhas_...`); operador escolhe qual exportar via menu.

**Alternativa:** ZIP único — mais um passo de implementação; pode vir depois.

### 3. file_selector no Windows

**Decisão:** pacote `file_selector` para `getSaveLocation` no desktop.

### 4. Lógica pura testável

**Decisão:** `CsvReportBuilder` puro recebe DTOs e retorna `String`; testes sem Flutter binding.

## Risks / Trade-offs

- **[Volume grande em "Tudo"]]** → aviso se > 50k linhas; exportar mesmo assim.
- **[Dados sensíveis (e-mail operador)]** → CSV fica no PC do posto; responsabilidade do cliente.

## Migration Plan

1. Deploy app Windows; botões visíveis no Painel.
2. Treinar supervisor: exportar ao fim do turno.

## Open Questions

- Incluir exportação de buffer de etiquetas nesta change ou separada?
