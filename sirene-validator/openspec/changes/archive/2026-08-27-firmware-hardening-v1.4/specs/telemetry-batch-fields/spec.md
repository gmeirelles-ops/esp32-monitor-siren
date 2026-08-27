## ADDED Requirements

### Requirement: Heartbeat inclui contexto de lote ativo

O firmware SHALL incluir no heartbeat MQTT os campos `numero_op`, `proximo_sequencial` e `aprovados` quando houver lote ativo; strings vazias ou zero quando em `IDLE`.

#### Scenario: Lote ativo

- **WHEN** há lote configurado OP `2026001` com sequencial 3 e 2 aprovados
- **THEN** o heartbeat contém `"numero_op":"2026001"`, `"proximo_sequencial":3`, `"aprovados":2`

#### Scenario: Sem lote

- **WHEN** o estado é `IDLE` sem lote ativo
- **THEN** o heartbeat contém `"numero_op":""`, `"proximo_sequencial":0`, `"aprovados":0`
