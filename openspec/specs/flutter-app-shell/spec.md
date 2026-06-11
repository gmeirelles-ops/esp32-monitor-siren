# flutter-app-shell Specification

## Purpose
TBD - created by archiving change flutter-companion-app. Update Purpose after archive.
## Requirements
### Requirement: Tema visual Diponto amber
O app Flutter SHALL aplicar uma paleta de cores amber como identidade visual primária, alinhada à marca Diponto, com fundo escuro para uso em ambiente industrial.

#### Scenario: Cores primárias aplicadas
- **WHEN** o app é iniciado
- **THEN** o tema Material 3 utiliza amber (`#FFB300`) como cor primária, amber escuro (`#FF8F00`) como secundária e fundo escuro (`#1A1A1A`) como surface

#### Scenario: Componentes seguem o tema
- **WHEN** o operador navega entre telas
- **THEN** AppBar, botões primários, FAB e indicadores ativos exibem a cor amber da marca

### Requirement: Navegação principal do app
O app SHALL oferecer navegação entre as seções: Dispositivos, Lote, Produtos, Etiquetas, Configurações e Admin.

#### Scenario: Acesso às seções
- **WHEN** o operador abre o app
- **THEN** uma barra de navegação permite alternar entre Dispositivos, Lote, Produtos, Etiquetas, Configurações e Admin

### Requirement: Configuração global do broker MQTT
O app SHALL permitir configurar e persistir o endereço do broker MQTT (host e porta) nas Configurações.

#### Scenario: Broker configurado
- **WHEN** o operador informa host `192.168.1.100` e porta `1883` e salva
- **THEN** o app persiste a configuração e utiliza esse endereço em todas as conexões MQTT subsequentes

#### Scenario: Broker padrão na primeira execução
- **WHEN** o app é executado pela primeira vez sem configuração prévia
- **THEN** o app exibe o valor padrão `mqtt://192.168.1.100:1883` (alinhado ao firmware) e solicita confirmação do operador

### Requirement: Logo e identidade Diponto
O app SHALL exibir o logo Diponto na AppBar e utilizar tipografia legível para ambiente de fábrica.

#### Scenario: Logo visível
- **WHEN** o operador está em qualquer tela principal
- **THEN** o logo Diponto é exibido na AppBar

