## ADDED Requirements

### Requirement: Identidade do operador no resultado de teste
O app SHALL registrar o identificador do operador autenticado (e-mail da conta Firebase Auth) em cada resultado de teste persistido, quando houver sessão ativa.

#### Scenario: Operador autenticado valida peça
- **WHEN** um resultado de teste é recebido e há operador autenticado
- **THEN** o resultado é persistido localmente com o e-mail do operador

#### Scenario: Sem operador autenticado
- **WHEN** um resultado de teste é recebido sem sessão ativa (ex.: plataforma sem Firebase ou sync desligado)
- **THEN** o resultado é persistido normalmente com operador ausente, sem bloquear o fluxo de etiquetas

### Requirement: Exibição do operador no resultado
O app SHALL exibir o operador associado ao último resultado de teste na tela de Lote, quando disponível.

#### Scenario: Card de resultado mostra operador
- **WHEN** o app exibe o card do último teste e há operador registrado
- **THEN** o card mostra o e-mail do operador que validou a peça
