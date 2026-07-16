## ADDED Requirements

### Requirement: Cadastro local de operadores
O app SHALL manter uma tabela SQLite de operadores com `codigo` (único), `nome` e flag `ativo`, permitindo criar, editar e desativar operadores sem dependência de Firebase.

#### Scenario: Novo operador cadastrado
- **WHEN** o supervisor preenche código e nome na aba Operadores de Cadastros e salva
- **THEN** o operador é persistido localmente e aparece na lista de operadores ativos

#### Scenario: Código duplicado
- **WHEN** o usuário tenta cadastrar um `codigo` já existente
- **THEN** o app bloqueia o salvamento e informa o conflito

#### Scenario: Operador desativado
- **WHEN** um operador é marcado como inativo
- **THEN** ele deixa de aparecer no seletor de operador ativo do turno

### Requirement: Seleção do operador ativo do turno
O app SHALL permitir selecionar um operador ativo, persistir a escolha entre sessões e exibir o operador corrente na shell do app.

#### Scenario: Operador selecionado no início do turno
- **WHEN** o operador escolhe seu nome no seletor de turno
- **THEN** o app persiste a seleção e exibe o operador na AppBar e na tela de Lote

#### Scenario: Nenhum operador selecionado
- **WHEN** não há operador ativo e o usuário tenta enviar `SET_BATCH`
- **THEN** o app bloqueia o envio e orienta a selecionar um operador

#### Scenario: Lista vazia de operadores
- **WHEN** não há operadores cadastrados
- **THEN** o app orienta cadastrar em Cadastros → Operadores antes de iniciar lote
