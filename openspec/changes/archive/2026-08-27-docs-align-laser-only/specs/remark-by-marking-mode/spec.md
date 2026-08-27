## ADDED Requirements

### Requirement: Remark é sempre regravação laser
O app SHALL oferecer remark de serial aprovado exclusivamente como **Regravar** (enfileirar na `mark_queue` com prioridade), com instrução de acionar F2 no DiatuCAD. Não há reimpressão ZPL.

#### Scenario: Regravar na consulta
- **WHEN** o operador confirma remark de serial aprovado
- **THEN** o serial é enfileirado na fila laser e a UI usa rótulo "Regravar"

#### Scenario: Auditoria
- **WHEN** a regravação é enfileirada/concluída conforme fluxo atual
- **THEN** o app registra auditoria local com modo laser (não `label`)
