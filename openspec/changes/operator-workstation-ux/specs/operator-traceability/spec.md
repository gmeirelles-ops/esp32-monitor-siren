## MODIFIED Requirements

### Requirement: Identidade do operador no resultado de teste
O app SHALL registrar o identificador do operador ativo do turno (código e nome do cadastro local) em cada resultado de teste persistido. Quando não houver operador local selecionado mas houver sessão Firebase autenticada, o app MAY usar o e-mail como fallback.

#### Scenario: Operador local selecionado valida peça
- **WHEN** um resultado de teste é recebido e há operador ativo do turno
- **THEN** o resultado é persistido localmente com identificação legível do operador (código e nome)

#### Scenario: Sem operador local nem Firebase
- **WHEN** um resultado de teste é recebido sem operador ativo e sem sessão Firebase
- **THEN** o resultado é persistido com operador ausente, sem bloquear etiquetas

#### Scenario: Fallback Firebase
- **WHEN** não há operador local selecionado mas o usuário está autenticado no Firebase
- **THEN** o resultado usa o e-mail autenticado como operador

### Requirement: Exibição do operador no resultado
O app SHALL exibir o operador associado ao último resultado de teste na tela de Lote e no Batch Live Dashboard, quando disponível.

#### Scenario: Card de resultado mostra operador
- **WHEN** o app exibe o card do último teste e há operador registrado
- **THEN** o card mostra o nome/código do operador que validou a peça
