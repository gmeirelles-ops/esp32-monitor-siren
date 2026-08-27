## MODIFIED Requirements

### Requirement: Disparo físico somente via fila laser
Após gerar serial aprovado, o app SHALL enfileirar a gravação na `mark_queue` (laser DiatuCAD). O app SHALL NOT acumular buffer ZPL nem enviar comandos a impressora de etiquetas. Texto de UI e specs relacionadas SHALL usar “gravação” / “Regravar”, não “etiqueta” / “reimprimir”, para esse fluxo.

#### Scenario: Aprovação enfileira laser
- **WHEN** um serial aprovado inédito é gerado
- **THEN** existe entrada pendente na fila de gravação laser

#### Scenario: Copy operador
- **WHEN** o gestor consulta um serial aprovado
- **THEN** a ação oferecida é Regravar (fila laser), não reimprimir etiqueta
