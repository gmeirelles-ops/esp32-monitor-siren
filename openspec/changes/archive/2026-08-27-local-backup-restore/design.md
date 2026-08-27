## Context

Drift persiste em `Documentos/sirene_app.sqlite` (`AppDatabase.dbFile()`, schema **20**). Já existe `FactoryResetService` que fecha o DB e apaga o arquivo — o restore deve reutilizar o mesmo padrão (close → replace → invalidate providers). Category **Manutenção** já existe nas Configurações.

Proposta anterior (arquivada 2026-08-27) não foi implementada; esta change retoma com schema atual e laser-only (sem buffer de etiquetas).

## Goals / Non-Goals

**Goals**

- Backup offline 100% local (sem nuvem).
- Restore em PC novo ou no mesmo posto.
- Recusar backup com `schemaVersion` **maior** que o app (pedir update do app).
- Aceitar backup com schema **menor** — Drift `onUpgrade` aplica migrations ao reabrir.

**Non-Goals**

- Backup automático agendado / cron.
- Upload do ZIP para Firestore.
- Backup parcial (só um lote).
- Criptografia do ZIP (produto interno na LAN).

## Decisions

1. **Formato** — `sirene_backup_YYYYMMDD_HHMMSS.zip` com:
   - `sirene_app.sqlite` (cópia do arquivo após checkpoint/close seguro)
   - `manifest.json` (`schemaVersion`, `stationId`, `appVersion`, `createdAt` ISO-8601, `formatVersion: 1`)
   - `prefs.json` — subset: MQTT, laser TCP, `station_id`, flags de setup (não incluir PIN/sessão)

2. **Export** — fechar Drift (ou `PRAGMA wal_checkpoint(FULL)` + copy) para snapshot consistente; preferir **close + copy + reopen** alinhado ao factory reset para evitar WAL parcial.

3. **Restore** — (a) contar SyncQueue pendente e avisar; (b) digitar `RESTAURAR`; (c) close DB; (d) substituir sqlite; (e) aplicar prefs do ZIP se presentes; (f) invalidate providers / pedir reinício se necessário.

4. **UI** — botões em Manutenção; `file_selector` para salvar/abrir ZIP no Windows.

5. **Deps** — adicionar pacote `archive` para ZIP.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Restore sobrescreve produção | Confirmação `RESTAURAR` + aviso sync pendente |
| App antigo abre DB novo | Recusar se schema backup > app |
| Prefs de outro posto | Manifest mostra `stationId`; operador confirma |

## Migration Plan

1. Implementar serviço + UI + testes unitários (manifest/schema).
2. Documentar backup semanal e troca de PC em PRODUCAO.
3. Smoke: backup → factory-ish wipe → restore → lotes/seriais presentes.

## Open Questions

- _(nenhuma)_ — prefs no ZIP incluídas por decisão 1.
