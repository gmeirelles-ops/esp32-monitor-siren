## Why

Hoje o app abre direto na estação de trabalho sem identificar quem está no posto; a seleção de operador é opcional e dispersa no fluxo de lote. Para auditoria e qualidade, cada sessão precisa começar com autenticação simples (PIN + operador cadastrado). Além disso, supervisores precisam de um relatório consolidado por número de série — não só uma lista de testes — com rastreabilidade completa da sirene (OP, produto, operador, dispositivo, veredito, potência, etiqueta e timestamps) sem exportar CSV manualmente.

## What Changes

- **BREAKING**: Tela inicial do app passa a ser **Login de Operador**; o shell principal só é acessível após autenticação com PIN válido de um operador ativo cadastrado.
- Tela de login exibe operadores ativos cadastrados (nome visível); o operador informa o PIN (campo `codigo` no cadastro) para entrar.
- Sessão de operador persistida entre reinicializações até logout explícito ou troca de operador.
- Nova tela **Relatório de Rastreabilidade** acessível na navegação principal (supervisor/qualidade).
- Busca por número de série (10 dígitos ou prefixo) com visão consolidada: dados do teste, OP, produto, operador, dispositivo, potência, veredito, data/hora, status de etiqueta e tentativas anteriores do mesmo serial.
- Ação de reimpressão de etiqueta a partir do relatório quando o serial foi aprovado.
- Logout de operador nas Configurações encerra a sessão e retorna à tela de login.
- Testes unitários para validação de PIN, queries de rastreabilidade e widget da tela de login.

## Capabilities

### New Capabilities

- `operator-pin-login`: gate de entrada com PIN e lista de operadores cadastrados; sessão persistente
- `siren-traceability-report`: relatório consolidado de rastreabilidade por número de série

### Modified Capabilities

- `flutter-app-shell`: tela inicial é login; navegação principal condicionada à sessão de operador
- `operator-traceability`: identidade do operador vem da sessão de login PIN (substitui seletor solto no início do turno)
- `serial-traceability`: consulta histórica completa por serial exposta na UI de relatório
- `batch-operator-ui`: operador ativo pré-preenchido pela sessão de login (sem seleção redundante obrigatória)

## Impact

- **App Flutter**: novo `operator_login_screen.dart`, `traceability_report_screen.dart`, `app.dart` (roteamento inicial), `operators_provider.dart` (sessão), `database.dart` (queries de rastreabilidade), `settings_screen.dart` (logout operador), remoção/simplificação do seletor obrigatório no Lote
- **SQLite**: sem migração de schema — reutiliza tabela `operators` (`codigo` = PIN) e `test_results`
- **Firebase Auth**: permanece opcional para sync em nuvem; login de operador local é independente
- **Firmware / MQTT**: sem alteração de contrato
