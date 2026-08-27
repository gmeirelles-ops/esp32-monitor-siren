## MODIFIED Requirements

### Requirement: Resultado offline não bloqueia marcação
- **WHEN** um teste é recebido e a nuvem está indisponível
- **THEN** o resultado é gravado no SQLite local normalmente, sem bloquear o fluxo de gravação laser
