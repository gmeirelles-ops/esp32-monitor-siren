## ADDED Requirements

### Requirement: Encerramento automático ao atingir meta
O Batch Live Dashboard SHALL enviar `END_BATCH` automaticamente quando `aprovados_no_lote >= quantidade_total` com `quantidade_total > 0`, após processar o resultado que completa a meta, sem exigir confirmação manual do operador.

#### Scenario: Meta atingida na última aprovação
- **WHEN** um teste aprovado eleva `aprovados_no_lote` até `quantidade_total`
- **THEN** o app imprime etiquetas órfãs se aplicável, publica `END_BATCH`, limpa o lote ativo e informa que o lote foi encerrado automaticamente

#### Scenario: Meta já atingida
- **WHEN** o lote já atingiu a meta e um novo `END_BATCH` automático seria redundante
- **THEN** o app não envia comandos duplicados de encerramento

### Requirement: Indicação visual de modo reteste no dashboard
Quando o modo reteste estiver ativo, o dashboard SHALL exibir banner ou badge distinto informando que testes não consomem serial nem cota.

#### Scenario: Banner de reteste ativo
- **WHEN** o checkbox Reteste está marcado
- **THEN** o dashboard exibe indicação "Modo reteste" visível junto ao cabeçalho do lote
