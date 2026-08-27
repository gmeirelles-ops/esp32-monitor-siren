## MODIFIED Requirements

### Requirement: Unicidade antes de emitir serial
O app SHALL verificar existência local do serial antes de emití-lo; se já existir, SHALL NOT enfileirar gravação laser e SHALL sinalizar conflito.

#### Scenario: Serial novo
- **WHEN** o serial não existe localmente
- **THEN** o serial é aceito e enfileirado na `mark_queue`
