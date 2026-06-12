## MODIFIED Requirements

### Requirement: Tela de cadastros unificada
O app SHALL oferecer a área **Cadastros** na navegação principal com abas **Produtos** e **Operadores**, agrupando o CRUD de SKUs e o cadastro de operadores do turno.

#### Scenario: Acesso a cadastros
- **WHEN** o usuário seleciona Cadastros na navegação
- **THEN** o app exibe abas Produtos e Operadores com listas e ações de criar/editar

#### Scenario: Produto cadastrado a partir de Cadastros
- **WHEN** o usuário cria ou edita um produto na aba Produtos
- **THEN** o comportamento de catálogo existente (limites, calibração) é preservado

#### Scenario: Operador cadastrado na mesma área
- **WHEN** o usuário cria um operador na aba Operadores
- **THEN** o operador fica disponível no seletor de turno da tela Lote
