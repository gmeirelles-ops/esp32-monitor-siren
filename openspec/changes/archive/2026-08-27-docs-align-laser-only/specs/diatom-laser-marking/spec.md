## ADDED Requirements

### Requirement: Servidor TCP para DiatuCAD
O app SHALL expor servidor TCP (porta configurável, padrão 9101) do qual o DiatuCAD solicita o próximo serial da fila de gravação.

#### Scenario: F2 consome fila
- **WHEN** o DiatuCAD solicita string via TCP e há serial pendente
- **THEN** o app devolve o serial e marca a entrada conforme o processador de fila

### Requirement: Fila persistente mark_queue
O app SHALL persistir gravações pendentes em SQLite e reprocessar falhas de forma visível ao operador.

#### Scenario: Offline / falha
- **WHEN** a entrega ao laser falha
- **THEN** o serial permanece pendente com erro visível e pode ser retentado

### Requirement: Único backend de marcação
O produto SHALL usar somente gravação laser Diatu/DiatuCAD; não há backend paralelo de etiquetas adesivas.

#### Scenario: Pós-aprovação
- **WHEN** uma peça é aprovada
- **THEN** o único efeito de marcação física iniciado pelo app é o enfileiramento laser
