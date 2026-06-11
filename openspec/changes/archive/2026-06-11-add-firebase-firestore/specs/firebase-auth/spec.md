## ADDED Requirements

### Requirement: Login de operador com e-mail e senha
O app SHALL oferecer tela de login Firebase Auth com campos de e-mail e senha, autenticando via `signInWithEmailAndPassword`.

#### Scenario: Login bem-sucedido
- **WHEN** o operador informa credenciais válidas e confirma o login
- **THEN** o app estabelece sessão autenticada e redireciona para a tela principal

#### Scenario: Credenciais inválidas
- **WHEN** o operador informa e-mail ou senha incorretos
- **THEN** o app exibe mensagem de erro em português sem expor detalhes técnicos do Firebase

### Requirement: Persistência de sessão
O app SHALL manter a sessão do operador entre reinicializações do aplicativo enquanto o token Firebase for válido.

#### Scenario: Reabertura do app com sessão ativa
- **WHEN** o operador fecha e reabre o app com sessão ainda válida
- **THEN** o app não exige novo login e a sincronização permanece habilitada se estava ativa

### Requirement: Logout do operador
O app SHALL permitir logout via Configurações, encerrando a sessão Firebase e desabilitando a sincronização em nuvem.

#### Scenario: Operador encerra sessão
- **WHEN** o operador aciona "Sair" nas Configurações
- **THEN** a sessão Firebase é encerrada, o toggle de sync é desabilitado e operações locais (MQTT, SQLite) continuam funcionando

### Requirement: Gate de sincronização por autenticação
O app SHALL impedir ativação da sincronização Firestore quando não houver operador autenticado.

#### Scenario: Tentativa de habilitar sync sem login
- **WHEN** o operador tenta habilitar sincronização em nuvem sem estar autenticado
- **THEN** o app redireciona para a tela de login ou exibe que login é obrigatório

### Requirement: Sem auto-registro de contas
O app SHALL NOT oferecer fluxo de criação de conta — contas são provisionadas externamente (Firebase Console ou Admin SDK).

#### Scenario: Operador sem conta
- **WHEN** um operador tenta login com e-mail não cadastrado
- **THEN** o app exibe mensagem orientando contato com o administrador do sistema
