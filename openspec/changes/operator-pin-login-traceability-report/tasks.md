## 1. Login de operador (PIN)

- [x] 1.1 Criar `operator_login_screen.dart` com lista de operadores ativos (nome), campo PIN mascarado e botão Entrar
- [x] 1.2 Implementar validação PIN ↔ `operators.codigo` e persistência via `setActiveOperator` / `AppConfig`
- [x] 1.3 Adicionar bloqueio de 5 tentativas / 30s por operador selecionado
- [x] 1.4 Exibir estado vazio com CTA para Cadastros quando não houver operadores ativos
- [x] 1.5 Refatorar `app.dart`: `home` condicional (login vs shell) baseado em `activeOperatorProvider`
- [x] 1.6 Adicionar logout/troca de operador em `settings_screen.dart` que limpa sessão e volta ao login
- [x] 1.7 Renomear rótulo "Código" para "PIN" em `operator_form_screen.dart` (sem migração de schema)

## 2. Shell e rastreabilidade do operador

- [x] 2.1 Garantir chip de operador na `DipontoAppBar` somente leitura (nome da sessão)
- [x] 2.2 Remover obrigatoriedade do seletor de operador no início do Lote; manter "Trocar operador" via Configurações
- [x] 2.3 Confirmar `resolveOperadorLabel` grava nome/código da sessão em cada `test_results`

## 3. Queries de rastreabilidade

- [x] 3.1 Implementar `getTraceabilityBySerial(String serial)` em `database.dart` (testes + etiqueta + produto)
- [x] 3.2 Implementar `searchSerialPrefixes(String prefix, {int limit = 50})` com debounce-friendly API
- [x] 3.3 Testes unitários Drift para histórico agregado, serial inexistente e múltiplas tentativas

## 4. Tela Relatório de rastreabilidade

- [x] 4.1 Criar `traceability_report_screen.dart` com campo de busca e debounce 300ms
- [x] 4.2 UI de relatório consolidado: cabeçalho (serial, produto, veredito), timeline de tentativas, card de etiqueta
- [x] 4.3 Lista de seleção quando prefixo retorna múltiplos seriais (máx. 50)
- [x] 4.4 Botão reimprimir etiqueta (reutilizar lógica existente de `label_print_logic`); desabilitar se reprovado
- [x] 4.5 Adicionar destino "Relatório" na navegação principal (`app.dart` — ícone e ordem Lote, Painel, Relatório, Etiquetas, Cadastros, Configurações)

## 5. Testes e validação

- [x] 5.1 Widget test: login com PIN correto navega ao shell; PIN incorreto exibe erro
- [x] 5.2 Widget test: relatório exibe timeline para serial com reprovação + aprovação
- [x] 5.3 Executar `flutter test` nos arquivos novos/alterados e corrigir falhas
