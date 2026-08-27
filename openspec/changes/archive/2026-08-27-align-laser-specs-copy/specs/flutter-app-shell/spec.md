## MODIFIED Requirements

### Requirement: Offline-first sem depender de nuvem
- **WHEN** Firebase não está configurado ou autenticado
- **THEN** funcionalidades locais (MQTT, SQLite, gravação laser) permanecem acessíveis

### Requirement: Marcação após aprovação sem telas extras
- **WHEN** um teste APROVADO é processado
- **THEN** o resultado é persistido e a gravação laser enfileirada sem exigir visita prévia a Dispositivos ou Lote
