# diatu-laser-marking Specification

## Purpose
Gravação permanente do serial ITF via laser Diatu/DiatuCAD (servidor TCP no app + MarkQueue).

## Requirements

### Requirement: Servidor TCP para DiatuCAD
O app SHALL expor servidor TCP (porta configurável, padrão 9101) do qual o DiatuCAD solicita o próximo serial da fila de gravação.

#### Scenario: F2 consome fila
- **WHEN** o DiatuCAD solicita string via TCP e há serial pendente
- **THEN** o app devolve o serial

### Requirement: Fila persistente mark_queue
O app SHALL persistir gravações pendentes em SQLite e reprocessar falhas de forma visível ao operador.

#### Scenario: Falha
- **WHEN** a entrega ao laser falha
- **THEN** o serial permanece pendente com erro visível

### Requirement: Único backend de marcação
O produto SHALL usar somente gravação laser Diatu/DiatuCAD.

#### Scenario: Pós-aprovação
- **WHEN** uma peça é aprovada
- **THEN** o único efeito de marcação física iniciado pelo app é o enfileiramento laser

### Requirement: Glossário Diaotu vs DiatuCAD
A documentação e esta capability SHALL distinguir: **Diaotu** = marca/modelo do laser (ex. B3); **DiatuCAD** = software de job e cliente TCP; APIs do app usam prefixo `Diatu*`. O produto SHALL NOT tratar “Diaotu” como erro ortográfico de “Diatu”.

#### Scenario: Operador lê referência laser
- **WHEN** consulta `docs/laser-reference/`
- **THEN** encontra o glossário e instruções de desativar Marca de controlo TCP no Diaotu sem confundir com DiatuCAD

### Requirement: Instrução de gravação = pedal (operador)
Textos voltados ao operador (fila, callout, remark, empty state) SHALL orientar a acionar o **pedal** para gravar. SHALL NOT exigir conhecimento de tecla F2 na mensagem principal.

#### Scenario: Serial na fila
- **WHEN** há serial pendente na `mark_queue`
- **THEN** a mensagem principal diz para acionar o pedal

