## Context

Existe código parcial de `AppGate`, `OperatorLoginScreen` e relatório por lote com exportação CSV (`batch_report_export.dart`). A change `operator-pin-login-traceability-report` foi aplicada no código mas não arquivada nas specs principais. O usuário reporta que a tela de login inicial ainda não está efetiva na experiência final e que relatórios precisam sair em **PDF com layout profissional** para impressão e arquivo.

## Goals / Non-Goals

**Goals:**
- Login por PIN como gate obrigatório e primeira tela visível ao abrir o app.
- Relatório por lote (lista OP → sirenes testadas) com filtros existentes.
- PDF formatado Diponto: cabeçalho, resumo, tabela, rodapé com data/posto.
- Impressão via diálogo do sistema (`printing`) e salvamento em `Documents/relatorios/`.
- Testes do builder PDF (bytes não vazios, colunas esperadas).

**Non-Goals:**
- PDF de Painel/throughput (fica em `production-reporting-export`).
- Login Firebase para nuvem (permanece em Configurações).
- Assinatura digital ou envio por e-mail do PDF.

## Decisions

### 1. Pacotes `pdf` + `printing`

**Decisão:** `package:pdf` para montar documento; `package:printing` para `layoutPdf` (preview + print dialog Windows).

**Alternativa:** HTML → print — rejeitada por layout inconsistente entre engines.

### 2. Layout PDF Diponto

**Decisão:** A4 retrato; faixa superior amber com texto "Diponto — Relatório de Produção"; bloco de metadados (período, filtros, OP, operador logado, data de geração); tabela zebrada com colunas conforme contexto:
- **Lista de lotes:** OP, total, aprovados, reprovados, yield %, período.
- **Detalhe do lote:** serial, veredito, potência, dispositivo, operador, data.

**Alternativa:** CSV only — insuficiente para impressão em qualidade.

### 3. Login gate

**Decisão:** `MaterialApp.home = AppGate`; sem rota alternativa para o shell. Revisar edge cases: operador desativado após sessão, lista vazia, loading state.

### 4. Botões na UI

**Decisão:** Menu "Exportar" com opções **PDF** (primário) e **CSV** (secundário) na lista e no detalhe do lote.

## Risks / Trade-offs

- **[Dependência printing no Windows]** → Testar em build release; fallback salvar PDF se diálogo falhar.
- **[Logo em PDF]** → Usar texto estilizado se asset bitmap não carregar no pacote pdf.
- **[Sobreposição com changes antigas]** → Esta change consolida login + PDF; arquivar `operator-pin-login-traceability-report` após apply.

## Migration Plan

1. Adicionar dependências `pdf` e `printing` ao `pubspec.yaml`.
2. Deploy app; operadores existentes mantêm PIN = `codigo`.
3. PDFs passam a ser o fluxo principal de impressão; CSV permanece.

## Open Questions

- Incluir QR do serial no PDF do detalhe? **Proposta:** fase 2; tabela textual nesta entrega.
