## Context

Drift usa arquivo SQLite em path do app Windows. Schema atual v8.

## Goals / Non-Goals

**Goals:**
- Backup offline, sem nuvem.
- Restore em mesma major version de schema ou com migration forward.

**Non-Goals:**
- Backup automático agendado.
- Sync de backup para Firestore.

## Decisions

### 1. Formato ZIP

**Decisão:** `sirene_backup_YYYYMMDD_HHMM.zip` contendo `sirene.db` + `manifest.json` (`schemaVersion`, `station_id`, `appVersion`, `createdAt`).

### 2. Restore

**Decisão:** fechar conexão Drift, substituir arquivo, reabrir app ou hot-restart; recusar se schema backup > app (pedir update do app).

### 3. Sync pendente

**Decisão:** dialog "Existem N pendências na fila" antes de restore.

## Risks / Trade-offs

- **[Restore sobrescreve tudo]** → confirmação dupla com digitar "RESTAURAR".

## Migration Plan

1. Documentar backup semanal no posto.
2. Testar restore em VM antes de produção.

## Open Questions

- Incluir SharedPreferences (MQTT host) no zip?
