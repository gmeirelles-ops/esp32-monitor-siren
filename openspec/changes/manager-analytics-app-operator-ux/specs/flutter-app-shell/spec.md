## MODIFIED Requirements

### Requirement: Indicador de conexão MQTT global
O app SHALL exibir o indicador de status da conexão MQTT (`ConnectionStatusBadge`) na AppBar de todas as telas principais. O indicador SHALL NOT exibir "Desconectado" quando o broker MQTT estiver conectado ou enquanto a conexão inicial estiver em andamento (`connecting` / `reconnecting`).

#### Scenario: Badge visível fora de Dispositivos
- **WHEN** o operador está na tela de Lote, Painel, Etiquetas ou Configurações
- **THEN** o badge de conexão MQTT permanece visível na AppBar

#### Scenario: Conexão estabelecida
- **WHEN** `MqttService.currentState` é `connected`
- **THEN** o badge exibe estado conectado (ex.: "MQTT OK") em verde

#### Scenario: Carregamento inicial do stream
- **WHEN** o `StreamProvider` de conexão ainda não emitiu evento mas o serviço já está `connecting` ou `connected`
- **THEN** o badge reflete o estado real do serviço, não "Desconectado"

#### Scenario: Queda de conexão refletida globalmente
- **WHEN** a conexão com o broker MQTT é perdida
- **THEN** o badge reflete o estado desconectado em qualquer tela principal

### Requirement: Navegação principal do app
O app SHALL oferecer navegação entre as seções: Lote, Relatório, Etiquetas (ou Gravação em modo laser), Cadastros e Configurações, acessível somente após autenticação do operador na tela de login. O item **Painel** analítico completo SHALL NOT permanecer na navegação do operador — métricas analíticas ficam no app gestor.

#### Scenario: Acesso às seções após login
- **WHEN** o operador autenticado abre o app
- **THEN** a barra de navegação permite alternar entre Lote, Relatório, Etiquetas/Gravação, Cadastros e Configurações, sem item Painel analítico

#### Scenario: Shell bloqueado sem login
- **WHEN** não há operador autenticado
- **THEN** o shell principal e sua navegação não são acessíveis

#### Scenario: Resumo mínimo opcional na Lote
- **WHEN** o operador está na tela de Lote
- **THEN** o app pode exibir contador simples de testes do dia (opcional), sem gráficos analíticos
