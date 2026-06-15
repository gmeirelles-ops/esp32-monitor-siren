## Context

O app Flutter sincroniza com Firestore via fila SQLite (`SyncQueue`). Hoje:

```
test_results/{numero_op}_{sequencial}   ← flat, idempotente
batches/{numero_op}                     ← metadados de lote separados
```

O SQLite local mantém `test_results` e `batches` com schema maduro; a mudança afeta **somente o espelhamento na nuvem**. Múltiplos postos escrevem no mesmo projeto; idempotência por `(numero_op, sequencial)` em reprovados e por `serial` em aprovados.

## Goals / Non-Goals

**Goals:**

- Hierarquia legível no Console Firebase: abrir OP → ver subcoleções `seriais` e `reprovadas`.
- Documento de lote com resumo (status, produto, quantidade, contadores, datas).
- Subcoleção `seriais/{serial}` com payload completo do teste aprovado.
- Subcoleção `reprovadas/{sequencial}` para reprovados e retestes reprovados (idempotência por sequencial).
- Fila local compatível com subcoleções sem quebrar offline-first.

**Non-Goals:**

- Alterar schema SQLite ou contratos MQTT/firmware.
- Leitura bidirecional nuvem → app (continua upload-only).
- Cloud Functions para agregação automática.
- Apagar dados flat legados no Firestore (migração opcional, não destrutiva).
- Duplicar aprovados em `reprovadas` — aprovados vão **somente** em `seriais`.

## Decisions

### 1. Esquema Firestore

```
test_results/{numero_op}                         ← documento LOTE
├── id_produto, ano, quantidade_total, device_id
├── status: "active" | "completed"
├── aprovados, reprovados (contadores)
├── started_at, ended_at, station_id
├── seriais/{serial}                             ← APROVADO (serial ITF = doc ID)
│   └── sequencial, veredito, potencia_media, operador, timestamp, is_retest, ...
└── reprovadas/{sequencial}                      ← REPROVADO (sequencial = doc ID)
    └── veredito, potencia_media, operador, timestamp, is_retest, device_id, ...
```

**Document ID do lote:** `numero_op` (ex.: `2026001`).

**Document ID em `seriais`:** serial ITF completo (ex.: `1232600018`).

**Document ID em `reprovadas`:** sequencial do lote como string (ex.: `"3"`).

**Reteste:** aprovado em reteste não gera serial → **não** grava em `seriais` nem `reprovadas` (só contadores no doc lote, se aplicável). Reprovado em reteste → `reprovadas/{sequencial}` com `is_retest: true`.

**Alternativa rejeitada:** subcoleção única `tentativas` para todos os testes — o operador pediu separação explícita aprovados vs reprovados.

### 2. Deprecar `batches/` no write path

Metadados de lote passam a ser upsert em `test_results/{numero_op}` nos eventos `SET_BATCH` e `END_BATCH`. Coleção `batches/` deixa de receber writes; documentos antigos permanecem para consulta histórica.

### 3. Extensão da SyncQueue

Adicionar coluna opcional `document_path` (text) em `SyncQueue`:

| Campo legado | Novo uso |
|--------------|----------|
| `collection` + `document_id` | Continua para `devices`, `products` |
| `document_path` | Caminho completo, ex.: `test_results/2026001/seriais/1232600018` ou `test_results/2026001/reprovadas/3` |

### 4. Ordem de escrita na fila

Para cada teste MQTT:

1. Upsert documento lote `test_results/{numero_op}` (merge contadores)
2. Se **APROVADO** com serial → upsert `seriais/{serial}`
3. Se **REPROVADO** → upsert `reprovadas/{sequencial}`
4. Se reteste aprovado → apenas passo 1 (sem subcoleção)

### 5. Regras e índices

- Rules: `match /test_results/{numeroOp}` + wildcard recursivo; imutabilidade em `seriais` e `reprovadas` (sem delete).
- Índice collection group em `seriais` para busca cross-lote por serial.

### 6. Migração de dados existentes

Script admin opcional: flat → hierarquia (`seriais` ou `reprovadas` conforme veredito); flat legado não apagado até validação.

## Risks / Trade-offs

- **[Nome `reprovadas` com maiúscula]** → Firestore é case-sensitive; usar exatamente `reprovadas` como pedido; documentar no GUIA.
- **[BREAKING para dashboards]** → script de migração; flat legado permanece.
- **[Reteste aprovado invisível na nuvem]** → aceitável; reteste não consome serial; rastreio completo permanece no SQLite local.

## Migration Plan

1. Deploy regras/índices.
2. Deploy app com novo sync.
3. (Opcional) Migrar flat → hierarquia.
4. Rollback: reverter app; dados hierárquicos não conflitam.

## Open Questions

- Contadores no doc lote: merge incremental no app vs reconcile no `END_BATCH` (recomendado: incremental + reconcile no encerramento).
