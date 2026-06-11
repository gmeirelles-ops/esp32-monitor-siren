# op-lock Specification

## Purpose
TBD - created by archiving change ota-campaign-calibration-oplock. Update Purpose after archive.
## Requirements
### Requirement: Bloqueio de OP encerrada
O app SHALL marcar uma OP como encerrada ao enviar `END_BATCH` e SHALL bloquear a configuração de um novo lote (`SET_BATCH`) que reutilize uma OP encerrada.

#### Scenario: OP travada ao encerrar lote
- **WHEN** o operador encerra um lote com `END_BATCH`
- **THEN** o app marca o `numero_op` correspondente como encerrado localmente

#### Scenario: Tentativa de reutilizar OP encerrada
- **WHEN** o operador tenta configurar um lote com um `numero_op` já encerrado
- **THEN** o app bloqueia o envio e orienta a usar uma nova OP

#### Scenario: OP inédita é permitida
- **WHEN** o operador configura um lote com um `numero_op` que não está encerrado
- **THEN** o app permite o envio normalmente

