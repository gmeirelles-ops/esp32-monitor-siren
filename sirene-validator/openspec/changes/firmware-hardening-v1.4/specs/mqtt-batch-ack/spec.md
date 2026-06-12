## ADDED Requirements

### Requirement: SET_BATCH bem-sucedido publica ACK

O firmware SHALL publicar em `sirene/<device_id>/status` um JSON de confirmação após `SET_BATCH` válido e persistido.

#### Scenario: Lote configurado

- **WHEN** `SET_BATCH` é aceito e o estado passa para `BATCH_READY`
- **THEN** o firmware publica JSON contendo `"tipo":"batch"`, `"evento":"configurado"`, `"numero_op"` e `"estado":"BATCH_READY"`

#### Scenario: Falha de validação

- **WHEN** `SET_BATCH` é rejeitado por campos inválidos
- **THEN** o firmware NÃO publica ACK de batch (apenas `rejeicao` existente)
