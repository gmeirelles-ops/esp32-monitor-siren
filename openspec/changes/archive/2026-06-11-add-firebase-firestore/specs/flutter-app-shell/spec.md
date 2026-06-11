## ADDED Requirements

### Requirement: Seção de nuvem nas Configurações
O app SHALL incluir nas Configurações uma seção "Nuvem" com: toggle de sincronização Firestore, campo `station_id`, status da fila de sync e botão de logout (quando autenticado).

#### Scenario: Operador configura posto
- **WHEN** o operador define `station_id` e salva nas Configurações
- **THEN** o valor é persistido em SharedPreferences e usado em gravações Firestore subsequentes

#### Scenario: Status da fila visível
- **WHEN** existem itens pendentes ou com falha na fila de sync
- **THEN** a seção Nuvem exibe contagem de pendências e falhas permanentes

### Requirement: Fluxo de login integrado à navegação
O app SHALL apresentar tela de login Firebase quando o operador tentar habilitar sincronização sem sessão ativa, mantendo acesso às demais seções sem autenticação.

#### Scenario: Uso local sem login
- **WHEN** o operador utiliza Dispositivos, Lote e Produtos sem estar autenticado
- **THEN** todas as funcionalidades locais (MQTT, SQLite, etiquetas) permanecem acessíveis

#### Scenario: Login solicitado para nuvem
- **WHEN** o operador tenta habilitar sincronização sem sessão
- **THEN** o app navega para a tela de login antes de ativar o toggle

### Requirement: Toggle de sync desabilitado por padrão
Em instalação nova, o toggle de sincronização Firestore SHALL iniciar desabilitado até que o operador autenticado o habilite explicitamente.

#### Scenario: Primeira execução após instalação
- **WHEN** o app é aberto pela primeira vez com Firebase configurado
- **THEN** a sincronização em nuvem está desligada e nenhum dado é enviado ao Firestore
