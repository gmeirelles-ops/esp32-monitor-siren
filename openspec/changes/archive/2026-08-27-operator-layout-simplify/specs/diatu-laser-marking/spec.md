## ADDED Requirements

### Requirement: Instrução de gravação = pedal (operador)
Textos voltados ao operador (fila, callout, remark, empty state) SHALL orientar a acionar o **pedal** para gravar. SHALL NOT exigir conhecimento de tecla F2 ou do nome DiatuCAD na mensagem principal (DiatuCAD MAY aparecer só em Configurações/docs de gestor).

#### Scenario: Serial na fila
- **WHEN** há serial pendente na `mark_queue`
- **THEN** a mensagem principal diz para acionar o pedal (ou equivalente curto em português claro)
