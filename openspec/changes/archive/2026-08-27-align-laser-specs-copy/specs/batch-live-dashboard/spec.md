## MODIFIED Requirements

### Requirement: Seriais pendentes de gravação no lote
O painel ao vivo SHALL refletir seriais aguardando gravação laser na OP (fila `mark_queue`), não buffer de etiquetas ZPL.

#### Scenario: Fila laser no lote
- **WHEN** um serial aprovado está pendente na `mark_queue` da OP
- **THEN** o painel indica pendência de gravação (não “etiqueta pendente”)

### Requirement: Encerramento de lote sem flush ZPL
Ao encerrar lote (manual ou automático), o app SHALL publicar `END_BATCH` e limpar estado do lote. O app SHALL NOT imprimir “etiquetas órfãs” ZPL.

#### Scenario: Fim de lote
- **WHEN** o lote é encerrado
- **THEN** o app publica `END_BATCH` e informa encerramento; gravações laser pendentes permanecem na fila até F2/processamento
