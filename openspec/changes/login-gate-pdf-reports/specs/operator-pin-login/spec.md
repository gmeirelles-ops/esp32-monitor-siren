## ADDED Requirements

### Requirement: Tela inicial de login de operador
O app SHALL exibir tela de login de operador como primeira tela ao iniciar, antes de qualquer seção do shell principal.

#### Scenario: App sem sessão ativa
- **WHEN** o app é aberto e não há operador autenticado na sessão
- **THEN** a tela de login é exibida em tela cheia, sem barra de navegação principal

#### Scenario: App com sessão válida
- **WHEN** o app é aberto e há operador autenticado com registro ainda ativo
- **THEN** o app redireciona diretamente para o shell principal

### Requirement: Lista de operadores cadastrados na login
A tela de login SHALL listar todos os operadores com status ativo, exibindo o nome de cada operador.

#### Scenario: Operadores ativos visíveis
- **WHEN** existem operadores ativos cadastrados
- **THEN** a login exibe a lista com nome de cada operador disponível para seleção

#### Scenario: Nenhum operador cadastrado
- **WHEN** não há operadores ativos cadastrados
- **THEN** a login informa que é necessário cadastrar operadores e oferece atalho para cadastro do primeiro operador

### Requirement: Autenticação por PIN do operador
O app SHALL autenticar o operador quando o PIN informado corresponder ao campo `codigo` do operador selecionado.

#### Scenario: PIN correto
- **WHEN** o operador seleciona seu nome na lista, informa o PIN correto e confirma entrada
- **THEN** a sessão é estabelecida e o app navega para o shell principal

#### Scenario: PIN incorreto
- **WHEN** o operador informa PIN que não corresponde ao operador selecionado
- **THEN** o app exibe mensagem de erro em português e mantém na tela de login

### Requirement: Persistência e logout da sessão
O app SHALL persistir a sessão entre reinicializações até logout ou troca de operador nas Configurações.

#### Scenario: Reabertura com sessão
- **WHEN** o operador fecha e reabre o app com sessão válida
- **THEN** o app não exige novo login

#### Scenario: Troca de operador
- **WHEN** o operador aciona troca de operador nas Configurações
- **THEN** a sessão é encerrada e a tela de login é exibida
