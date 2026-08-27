## MODIFIED Requirements

### Requirement: Configurações laser-only
A tela de Configurações SHALL agrupar Broker MQTT, Gravação laser (DiatuCAD) e Nuvem/Firestore. SHALL NOT expor card “Impressora Zebra” nem seletor Etiquetas/Laser.

#### Scenario: Gestor abre Configurações
- **WHEN** o gestor abre Configurações em desktop
- **THEN** vê opções laser e não vê controles de impressora Zebra/ZPL

### Requirement: Empty state de gravação
Telas que listam fila laser SHALL, quando vazias, orientar que seriais aparecerão após testes aprovados (não “etiquetas pendentes”).
