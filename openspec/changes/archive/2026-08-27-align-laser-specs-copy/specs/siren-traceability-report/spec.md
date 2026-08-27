## MODIFIED Requirements

### Requirement: Relatório de rastreabilidade por serial
Tela de relatório / consulta SHALL permitir busca local, timeline de tentativas e **Regravar** (fila laser) para seriais aprovados. SHALL NOT oferecer reimpressão ZPL nem status de “etiqueta gerada” baseado em buffer ZPL.

#### Scenario: Remark laser
- **WHEN** o gestor aciona Regravar em serial aprovado
- **THEN** o app enfileira na `mark_queue` (pinned) e orienta F2 no DiatuCAD
