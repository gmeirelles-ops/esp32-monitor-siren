## MODIFIED Requirements

### Requirement: Navegação principal desktop
O app SHALL exibir item de navegação **Etiquetas** quando modo Etiquetas estiver ativo, ou **Gravação** quando modo Gravação laser estiver ativo, mantendo ícone e badge de pendências coerentes com o backend ativo.

#### Scenario: Modo etiquetas
- **WHEN** MarkingMode é Etiquetas
- **THEN** a rail exibe "Etiquetas" com badge do buffer de impressão

#### Scenario: Modo laser
- **WHEN** MarkingMode é Gravação laser
- **THEN** a rail exibe "Gravação" com badge da fila de gravações pendentes

### Requirement: Configurações de impressora e marcação
A tela Configurações SHALL agrupar opções Zebra (visíveis só em modo Etiquetas) e opções laser Diatom (visíveis só em modo Gravação laser), incluindo seletor de modo no topo da seção.

#### Scenario: Alternância de modo
- **WHEN** o operador troca de Etiquetas para Gravação laser
- **THEN** campos Zebra são ocultados e campos laser (host, porta, teste) são exibidos
