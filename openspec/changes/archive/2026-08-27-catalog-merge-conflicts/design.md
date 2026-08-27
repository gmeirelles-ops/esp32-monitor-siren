## Context

`CatalogCloudService.pull()` faz upsert incondicional. Firestore `products` tem `updated_at` e pode ter `updated_by_station`.

## Goals / Non-Goals

**Goals:**
- Nunca sobrescrever silenciosamente calibração divergente.
- Fluxo claro para supervisor no pull manual e no pull automático ao habilitar sync.

**Non-Goals:**
- CRDT ou sync bidirecional em tempo real.
- Merge automático por "mais recente" sem confirmação em campos críticos.

## Decisions

### 1. Campos críticos

**Decisão:** conflito se diferente em: `potencia_min`, `potencia_max`, `potencia_ref`, `tolerancia_pct`, `tempo_teste_sec`, `calibrado_em`, `calibrado_device_id`.

### 2. Fluxo UI

**Decisão:** após pull, se `conflicts.isNotEmpty`, modal lista produtos com diff resumido; ações em lote "Aceitar todos remotos" / "Manter todos locais" / escolha individual.

### 3. Pull automático ao habilitar sync

**Decisão:** se conflitos, não aplicar remotos automaticamente — abrir modal antes de concluir.

### 4. Schema SQLite

**Decisão:** opcional `last_synced_at`, `remote_updated_at` em products para auditoria local.

## Risks / Trade-offs

- **[Mais cliques no pull]** → necessário para segurança operacional.

## Migration Plan

1. Deploy app; primeiro pull pós-update pode mostrar muitos conflitos se bases divergiram — comunicar equipe.

## Open Questions

- Política default quando operador fecha modal sem escolher?
