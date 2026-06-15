## ADDED Requirements

### Requirement: Modo reteste no firmware
O dispositivo SHALL aceitar flag `modo_reteste` na configuração de lote (`SET_BATCH`). Quando `modo_reteste` é verdadeiro, aprovações SHALL NOT incrementar `aprovados` nem `proximo_sequencial`, e SHALL NOT disparar encerramento por cota atingida.

#### Scenario: Aprovação em modo reteste
- **WHEN** `modo_reteste` é true e uma sirene é aprovada
- **THEN** o dispositivo publica resultado MQTT com veredito e potência, mantém `aprovados` e `proximo_sequencial` inalterados e não envia `END_BATCH` por cota

#### Scenario: Reprovação em modo reteste
- **WHEN** `modo_reteste` é true e uma sirene é reprovada
- **THEN** o dispositivo publica resultado MQTT sem alterar contadores do lote

#### Scenario: Modo reteste desativado
- **WHEN** `modo_reteste` é false ou ausente e uma sirene é aprovada
- **THEN** o dispositivo incrementa `aprovados` e `proximo_sequencial` conforme comportamento existente

### Requirement: Persistência de modo reteste
O dispositivo SHALL persistir o valor de `modo_reteste` no contexto de lote em NVS junto aos demais parâmetros até `END_BATCH`.

#### Scenario: Reboot com reteste ativo
- **WHEN** o dispositivo reinicia com lote ativo e `modo_reteste` true em NVS
- **THEN** o modo reteste permanece ativo após restauração do lote
