## MODIFIED Requirements

### Requirement: Identidade do operador no resultado de teste
O app SHALL registrar o identificador do operador autenticado na sessão de login (nome e código/PIN) em cada resultado de teste persistido.

#### Scenario: Operador autenticado valida peça
- **WHEN** um resultado de teste é recebido e há operador autenticado na sessão
- **THEN** o resultado é persistido localmente com o rótulo do operador (nome e código)

#### Scenario: Sem operador autenticado
- **WHEN** um resultado de teste é recebido sem sessão de operador ativa
- **THEN** o cenário é excepcional pois o shell exige login; o app não deve operar testes sem sessão ativa

### Requirement: Exibição do operador no resultado
O app SHALL exibir o operador da sessão ativa na AppBar e no card do último teste na tela de Lote.

#### Scenario: Operador visível na AppBar
- **WHEN** o operador autenticado navega no shell
- **THEN** a AppBar exibe o nome do operador da sessão

#### Scenario: Card de resultado mostra operador
- **WHEN** o app exibe o card do último teste
- **THEN** o card mostra o operador que validou a peça conforme sessão de login
