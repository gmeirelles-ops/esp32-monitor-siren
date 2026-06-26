# operator-pin-login Specification

## Purpose
TBD - created by archiving change logout-on-exit-batch-retest-dev. Update Purpose after archive.
## Requirements
### Requirement: Tela inicial de login de operador
O app SHALL exibir tela de login de operador como primeira tela ao iniciar, antes de qualquer seção do shell principal.

#### Scenario: App aberto sem operador na sessão atual
- **WHEN** o app é iniciado (nova execução)
- **THEN** a tela de login é exibida em tela cheia, sem barra de navegação principal

#### Scenario: Sessão não restaurada entre execuções
- **WHEN** o operador fechou o app após login bem-sucedido e reabre o aplicativo
- **THEN** o app exige novo login e não restaura automaticamente o operador anterior

### Requirement: Lista de operadores cadastrados na login
A tela de login SHALL listar todos os operadores com status ativo, exibindo o nome de cada operador.

#### Scenario: Operadores ativos visíveis
- **WHEN** existem operadores ativos cadastrados
- **THEN** a login exibe a lista com nome de cada operador disponível para seleção

#### Scenario: Nenhum operador cadastrado
- **WHEN** não há operadores ativos cadastrados
- **THEN** a login informa que é necessário cadastrar operadores e oferece atalho para Cadastros quando aplicável

### Requirement: Autenticação por PIN do operador
O app SHALL autenticar o operador quando o PIN informado corresponder ao campo `codigo` do operador selecionado.

#### Scenario: PIN correto
- **WHEN** o operador seleciona seu nome na lista, informa o PIN correto e confirma entrada
- **THEN** a sessão é estabelecida para a execução atual e o app navega para o shell principal

#### Scenario: PIN incorreto
- **WHEN** o operador informa PIN que não corresponde ao operador selecionado
- **THEN** o app exibe mensagem de erro em português e mantém na tela de login

#### Scenario: PIN mascarado
- **WHEN** o operador digita o PIN
- **THEN** o campo exibe caracteres mascarados

### Requirement: Sessão válida apenas na execução atual
O app SHALL manter o operador autenticado somente durante a execução em andamento do processo, sem persistir identificador de operador ativo em armazenamento local entre reinicializações.

#### Scenario: Fechar e reabrir aplicativo
- **WHEN** o operador encerra o processo do app e inicia novamente
- **THEN** nenhum identificador de operador ativo é lido do armazenamento persistente para pular o login

#### Scenario: Sessão durante uso contínuo
- **WHEN** o operador navega entre telas sem fechar o app
- **THEN** a sessão do operador permanece ativa sem novo login

#### Scenario: Troca de operador durante a sessão
- **WHEN** o operador aciona "Trocar operador" nas Configurações
- **THEN** a sessão da execução atual é encerrada e a tela de login é exibida

### Requirement: Logout de operador
O app SHALL permitir encerrar a sessão do operador nas Configurações, retornando à tela de login.

#### Scenario: Operador encerra sessão
- **WHEN** o operador aciona "Sair" ou "Trocar operador" nas Configurações
- **THEN** a sessão local é encerrada e a tela de login é exibida

### Requirement: Bloqueio por tentativas inválidas
O app SHALL bloquear novas tentativas de PIN por 30 segundos após 5 falhas consecutivas para o mesmo operador selecionado.

#### Scenario: Quinta tentativa falha
- **WHEN** o operador erra o PIN pela quinta vez consecutiva
- **THEN** o app exibe contagem regressiva de bloqueio e desabilita o botão de entrada por 30 segundos

