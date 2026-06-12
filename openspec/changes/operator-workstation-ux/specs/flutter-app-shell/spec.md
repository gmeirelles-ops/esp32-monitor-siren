## MODIFIED Requirements

### Requirement: Navegação principal do app
O app SHALL oferecer navegação principal com **Lote** como destino inicial padrão, seguido de Painel, Etiquetas, Cadastros e Configurações. A tela dedicada de Dispositivos e Admin SHALL NOT aparecer como destino de primeiro nível na navegação.

#### Scenario: Abertura do app
- **WHEN** o operador inicia o aplicativo
- **THEN** a primeira tela exibida é Lote, não Dispositivos

#### Scenario: Acesso a dispositivos
- **WHEN** o usuário precisa ver a lista técnica de dispositivos
- **THEN** o app oferece acesso via Configurações (ou equivalente secundário), reutilizando a tela de monitoramento existente

#### Scenario: Acesso a Admin/OTA
- **WHEN** o supervisor precisa de campanha OTA
- **THEN** o app oferece acesso via Configurações, fora da navegação principal do operador

### Requirement: Shell visual unificada
O app SHALL usar AppBar consistente em desktop e mobile, exibindo status MQTT e operador ativo do turno em todas as telas principais.

#### Scenario: Mobile com AppBar
- **WHEN** o app roda em layout mobile
- **THEN** as telas principais exibem AppBar com título, badge MQTT e indicador de operador ativo

#### Scenario: Desktop com NavigationRail
- **WHEN** o app roda em layout desktop
- **THEN** o NavigationRail contém cinco destinos (Lote, Painel, Etiquetas, Cadastros, Configurações) e a AppBar global mostra operador e MQTT
