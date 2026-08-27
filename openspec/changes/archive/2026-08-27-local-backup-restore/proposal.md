## Why

Histórico de produção, catálogo, MarkQueue, SyncQueue e operadores vivem no SQLite do PC Windows. Troca de máquina, disco corrompido ou reinstalação sem backup perde dados offline e pendências de sync. Produto interno precisa de backup/restore simples no próprio posto.

## What Changes

- Exportar backup ZIP do SQLite (+ manifest JSON: `schemaVersion`, `station_id`, `appVersion`, `createdAt`).
- Incluir snapshot opcional de prefs operacionais (MQTT/laser/`station_id`) no ZIP para troca de PC sem reconfigurar tudo.
- Restaurar com validação de schema, aviso se SyncQueue pendente, confirmação explícita.
- UI em **Configurações → Manutenção**: "Fazer backup" / "Restaurar backup".
- Documentar procedimento de troca de PC em `docs/PRODUCAO.md`.

## Capabilities

### New Capabilities

- `local-backup`: export/import do banco local (+ prefs) via ZIP

### Modified Capabilities

- `flutter-app-shell`: ações de manutenção (backup/restore) ao lado do factory reset
- `project-documentation`: checklist de backup / troca de posto

## Impact

- `sirene_app`: novo `BackupService`, seção Manutenção, dep `archive` (ZIP), `file_selector` já existe
- `docs/PRODUCAO.md`
- Sem mudança de firmware / MQTT / Firestore schema
