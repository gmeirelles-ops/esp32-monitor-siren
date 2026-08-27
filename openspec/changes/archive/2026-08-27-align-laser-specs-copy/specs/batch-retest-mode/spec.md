## MODIFIED Requirements

### Requirement: Reteste sem gerar serial nem gravação
Com modo reteste ativo, o app SHALL processar resultados mas SHALL NOT gerar serial, incrementar contador, enfileirar `mark_queue` nem avançar `proximo_sequencial` local do lote.

#### Scenario: Aprovado em reteste
- **WHEN** chega APROVADO com reteste ativo
- **THEN** o resultado é persistido sem serial e sem entrada na fila laser
