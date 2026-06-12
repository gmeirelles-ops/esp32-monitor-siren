## ADDED Requirements

### Requirement: Sequencial incremental por aprovação no lote ativo
O app SHALL atribuir um sequencial distinto a cada aprovação dentro do mesmo lote, calculado como o `proximo_sequencial` inicial do lote mais o número de aprovados já emitidos com serial naquela OP, alinhado ao comportamento do firmware.

#### Scenario: Quatro aprovações geram sequenciais 1 a 4
- **WHEN** um lote é configurado com `proximo_sequencial: 1` e quatro testes são APROVADOS na mesma OP
- **THEN** o app emite seriais com sequenciais 1, 2, 3 e 4 respectivamente

#### Scenario: Reprovação não consome sequencial
- **WHEN** um teste é REPROVADO no meio do lote
- **THEN** o próximo teste APROVADO usa o mesmo sequencial que o firmware atribuiria (sem pular número por causa da reprovação)

### Requirement: Estado do lote reflete sequencial corrente
Após cada serial emitido com sucesso, o app SHALL atualizar `activeBatch.proximoSequencial` para `sequencial_emitido + 1` quando o lote ativo corresponder à mesma OP.

#### Scenario: activeBatch avança após aprovação
- **WHEN** um serial é gerado para a OP do lote ativo com sequencial 3
- **THEN** `activeBatch.proximoSequencial` passa a ser 4 antes do próximo teste
