## ADDED Requirements

### Requirement: Modo de marcação configurável
O app SHALL oferecer em Configurações a escolha entre `Etiquetas (Zebra ZT230)` e `Gravação laser (Diatom)`, persistida localmente por posto.

#### Scenario: Modo etiquetas
- **WHEN** o operador seleciona modo Etiquetas
- **THEN** o fluxo de buffer ZPL e impressora Zebra permanece ativo; gravação laser não é acionada

#### Scenario: Modo laser
- **WHEN** o operador seleciona modo Gravação laser
- **THEN** aprovações disparam envio ao laser Diatom; buffer ZPL automático de múltiplos de 3 não é acionado

### Requirement: Configuração de rede do laser
O app SHALL persistir `laser_host`, `laser_port` e opcionalmente `laser_command_template` para o backend TCP.

#### Scenario: Host configurado
- **WHEN** o operador informa IP `192.168.1.60` e porta `9000` nas Configurações
- **THEN** tentativas de gravação usam esse endpoint até alteração
