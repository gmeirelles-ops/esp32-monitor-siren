## ADDED Requirements

### Requirement: Limpeza de sessão de operador ao encerrar o app
O app SHALL registrar observador de ciclo de vida e limpar `activeOperatorId` quando o processo for encerrado ou a janela fechada (`AppLifecycleState.detached`, e estados equivalentes de encerramento na plataforma desktop).

#### Scenario: Fechar janela no desktop
- **WHEN** o operador fecha a janela principal do app no Windows/Linux/macOS
- **THEN** `activeOperatorId` é removido do armazenamento local antes do término do processo

#### Scenario: Próxima abertura exige login
- **WHEN** o app é iniciado após encerramento completo do processo anterior
- **THEN** `activeOperatorId` é nulo e a tela de login é exibida
