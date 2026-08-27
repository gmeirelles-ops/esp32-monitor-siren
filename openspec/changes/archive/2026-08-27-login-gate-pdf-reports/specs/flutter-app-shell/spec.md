## MODIFIED Requirements

### Requirement: Navegação principal do app
O app SHALL oferecer navegação entre as seções: Lote, Painel, Relatório, Etiquetas, Cadastros e Configurações, acessível somente após autenticação do operador na tela de login.

#### Scenario: Acesso às seções após login
- **WHEN** o operador autenticado abre o app
- **THEN** uma barra de navegação permite alternar entre Lote, Painel, Relatório, Etiquetas, Cadastros e Configurações

#### Scenario: Shell bloqueado sem login
- **WHEN** não há operador autenticado
- **THEN** o shell principal e sua navegação não são acessíveis

### Requirement: Fluxo de login integrado à navegação
O app SHALL exibir login de operador local como gate inicial obrigatório e manter login Firebase opcional nas Configurações → Nuvem para sincronização.

#### Scenario: Uso local após login de operador
- **WHEN** o operador autenticado utiliza Lote, Painel e Etiquetas sem sessão Firebase
- **THEN** todas as funcionalidades locais (MQTT, SQLite, etiquetas) permanecem acessíveis

#### Scenario: Login Firebase para nuvem
- **WHEN** o operador tenta habilitar sincronização sem sessão Firebase
- **THEN** o app navega para a tela de login Firebase antes de ativar o toggle
