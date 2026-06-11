## Context

`products` sobe via fila (`enqueueProduct` → `products/{id_produto}`). Não há leitura. `test_results` guarda `serial`, `numeroOp` localmente. Firebase só existe em Windows/Android (Linux desabilitado). ZPL imprime 1–3 seriais por linha (`generateZplLabelRow`).

## Goals / Non-Goals

**Goals:**

- Compartilhar catálogo entre postos via pull, sem quebrar operação offline.
- Reimprimir etiqueta de um serial já validado.

**Non-Goals:**

- Sincronização em tempo real (snapshot listeners) do catálogo — pull sob demanda basta.
- Resolver conflito sofisticado de edição concorrente (adota last-writer-wins por `id_produto`).

## Decisions

### 1. Pull = upsert por `id_produto`

`pullCatalogFromCloud` lê todos os docs de `products`, converte cada um e chama `upsertProduct` (insertOnConflictUpdate). Last-writer-wins: o doc da nuvem sobrescreve o local.

**Trade-off:** um posto que calibrou localmente e ainda não subiu pode ser sobrescrito pelo pull. Mitigação: o pull automático ocorre ao **habilitar** o sync, **após** o push do catálogo local (`syncCatalogToCloud` já roda antes). O botão manual fica sob controle do operador.

### 2. Mapper reverso puro e testável

```
ParsedProduct? productFromFirestore(Map<String, dynamic> data)
```

Função pura (sem dependência de Firebase): aceita `calibrado_em` como `String` ISO ou `DateTime`; números como `int`/`double`. Retorna `null` se faltar `id_produto`. O `CatalogCloudService` (que importa `cloud_firestore`) normaliza `Timestamp → DateTime` antes de chamar o mapper, preservando a testabilidade.

### 3. `CatalogReader` injetável

```
typedef CatalogReader = Future<List<Map<String, dynamic>>> Function();
```

`CatalogCloudService` recebe um reader (produção: `FirebaseFirestore.collection('products').get()`; teste: lista fixa) e o `AppDatabase`. Retorna a contagem de produtos aplicados.

### 4. Reimpressão por serial

`findTestResultBySerial(serial)` busca exata em `test_results`; `searchSerials(query, limit)` faz `LIKE` para autocompletar. UI em Etiquetas: campo de busca → exibe OP/veredito/data → botão "Reimprimir" envia `generateZplLabelRow([serial])` à impressora. Reimpressão **não** mexe no buffer (é avulsa).

## Risks / Trade-offs

- **[Risco] Pull sobrescreve calibração local recente** → mitigado pela ordem push-antes-de-pull e botão manual.
- **[Risco] Reimpressão de serial reprovado** → a busca só retorna seriais existentes (aprovados têm serial); reprovados não têm serial, logo não aparecem.

## Migration Plan

1. Mapper reverso + testes.
2. `CatalogCloudService` + provider + helper + gancho no enable.
3. Botão de pull em Configurações.
4. Métodos de busca no banco + UI de reimpressão.
5. `flutter analyze`/`test`.

Sem migração de schema. Rollback trivial (código aditivo).
