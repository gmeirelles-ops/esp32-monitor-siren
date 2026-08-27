## Why

O posto precisa identificar o operador antes de qualquer ação — hoje o fluxo de login por PIN existe parcialmente no código, mas ainda não está consolidado como experiência inicial confiável (gate único, bootstrap sem operadores, troca de sessão). Supervisores e qualidade também precisam imprimir relatórios de lote em PDF com layout profissional Diponto para arquivo e impressão, não apenas CSV cru.

## What Changes

- Consolidar **tela de login de operador** como primeira tela do app: lista de operadores ativos (nome visível), autenticação por PIN (`codigo`), sessão persistente e retorno ao login ao trocar operador.
- Bootstrap: quando não há operadores cadastrados, CTA para cadastro inicial antes de entrar no shell.
- Relatório por **lotes (OP)**: lista filtrada de lotes; ao clicar, todas as sirenes testadas no lote.
- **Exportação e impressão em PDF** com layout Diponto (logo, cabeçalho, tabela legível, resumo de yield) para lista de lotes e detalhe de um lote.
- Diálogo de impressão do sistema (Windows) e opção de salvar PDF em `Documents/relatorios/`.
- Manter exportação CSV como alternativa; PDF passa a ser o formato principal de "imprimir relatório".
- Testes unitários do gerador PDF e widget do login.

## Capabilities

### New Capabilities

- `operator-pin-login`: gate de entrada com PIN, lista de operadores e sessão persistente
- `batch-traceability-report`: relatório por lote com lista de OPs, drill-down de sirenes e filtros
- `batch-report-pdf`: geração de PDF formatado e impressão/salvamento

### Modified Capabilities

- `flutter-app-shell`: tela inicial obrigatoriamente é login; shell só após autenticação
- `operator-traceability`: operador da sessão de login gravado em cada teste

## Impact

- **App Flutter**: `app.dart` (`AppGate`), `operator_login_screen.dart`, `traceability_report_screen.dart`, `batch_report_detail_screen.dart`, novo módulo `batch_report_pdf.dart`, `pubspec.yaml` (`pdf`, `printing`)
- **Sem impacto** em firmware, MQTT ou Firestore
