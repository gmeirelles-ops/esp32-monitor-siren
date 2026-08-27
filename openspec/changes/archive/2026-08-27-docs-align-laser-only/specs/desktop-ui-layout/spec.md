## ADDED Requirements

### Requirement: Configurações sem impressora Zebra
A tela de Configurações e o shell do posto SHALL expor configuração de **gravação laser** (porta TCP, diagnóstico) e SHALL NOT oferecer seletor Etiquetas/Laser, host/porta de impressora Zebra, nem modo USB RAW de etiquetas.

#### Scenario: Operador abre Configurações
- **WHEN** o gestor abre Configurações
- **THEN** vê opções laser e não vê controles de impressora Zebra / ZPL

### Requirement: Navegação Gravação
O item de menu de marcação física SHALL ser **Gravação** (fila laser), sem fluxo de buffer de etiquetas Zebra.

#### Scenario: Menu operador
- **WHEN** o operador autenticado vê a navegação principal
- **THEN** existe entrada para Gravação laser e não para fila de etiquetas ZPL
