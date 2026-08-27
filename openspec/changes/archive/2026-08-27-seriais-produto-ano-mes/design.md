## Context

Hoje cada aprovação sincroniza em `test_results/{numero_op}/seriais/{serial}` (navegação por lote). O contador de emissão (`serial_counters`) permanece só no SQLite local. Gestores precisam navegar no Firebase Console por produto e mês de produção.

Decisões do usuário: espelhar serial aprovado (não só contador); manter path por OP; `{ano}`/`{mes}` do dia do teste.

## Goals / Non-Goals

**Goals:**

- Dupla gravação no sync: path por lote + path `seriais/{produto}/anos/{ano}/meses/{mes}/itens/{serial}`
- Payload idêntico ao documento de lote (campos de `mapSerialDocument`) + path navegável no Console
- `{ano}` = ano civil `YYYY` e `{mes}` = `MM` derivados do timestamp do teste (timezone America/Sao_Paulo)
- Rules Firestore permitindo create/update autenticado nessa árvore; delete fechado ou só manager

**Non-Goals:**

- Migrar / backfill histórico de seriais já existentes na nuvem (pode ser script posterior)
- Mudar `serial_counters` local ou sincronizar contadores
- Remover ou alterar schema por lote
- UI nova no app para navegação do catálogo (só sync + Console)
- Espelhar reprovações nessa árvore

## Decisions

### D1 — Path Firestore com coleções intercaladas

Firestore exige alternância collection/document. Usar:

```
seriais/{id_produto}/anos/{YYYY}/meses/{MM}/itens/{serial}
```

- `id_produto`: 3 dígitos do SKU
- `YYYY` / `MM`: do **timestamp do teste** em `America/Sao_Paulo` (não do ano embutido no ITF)
- Document ID folha = serial ITF completo

**Alternativas:** path “achatado” `seriais/{produto_ano_mes}/…` — pior no Console. Usar ano de 2 dígitos do ITF — diverge do “dia do teste”.

### D2 — Dupla escrita na mesma `enqueueTestResult`

Quando houver serial aprovado, além de `serialPath(numeroOp, serial)`, enfileirar `catalogSerialPath(idProduto, yyyy, mm, serial)` com o mesmo payload (`operation: 'set'`). Idempotente no reprocessamento da fila.

**Alternativas:** Cloud Function espelhando — atraso/custo/ indirection; rejeitado.

### D3 — Timezone fixa SPT

Converter `timestamp` (UTC na fila) para `America/Sao_Paulo` só para derivar `YYYY`/`MM`. Evita serial “cair” no mês anterior/próximo por UTC.

### D4 — Docs pais opcionais

Não exigir documentos intermediários preenchidos; a primeira escrita em `itens/{serial}` já cria a árvore visível. MAY gravar stub `updated_at` nos pais se facilitar UI — fora do MVP.

### D5 — Rules

```
match /seriais/{productId}/anos/{year}/meses/{month}/itens/{serial} {
  allow read: if isAuthenticated();
  allow create, update: if isAuthenticated() && hasStationId();
  allow delete: if isManager();
}
```

Alinhado a `seriais` sob lote (create/update autenticado com `station_id`).

## Risks / Trade-offs

- **[Duplicação de storage / custo de escrita]** → Mitigação: só aprovados com serial; payload pequeno; aceito pelo requisito “manter os dois”.
- **[Ano do ITF ≠ ano civil do teste]** (teste em janeiro de serial do ano anterior) → Mitigação: documentar que a árvore usa dia do teste; campo `ano` no payload continua sendo o do ITF.
- **[Timezone errada em posto sem noção de fuso]** → Mitigação: SPT fixo, consistente com operação BR.
- **[Consulta antiga por collection group `seriais`]** → Mitigação: path novo usa coleção folha `itens`, não `seriais`; collection group existente em lotes permanece.

## Migration Plan

1. Deploy rules + índices (se collection group futura em `itens` for desejada; v1 sem índice novo obrigatório).
2. Release app com dupla enfileiração.
3. Seriais novos passam a aparecer na árvore; histórico antigo só sob `test_results` até backfill opcional.
4. Rollback: remover enqueue do path catálogo; docs já escritos permanecem inofensivos.

## Open Questions

Nenhum bloqueante. Backfill histórico fica como follow-up opcional.
