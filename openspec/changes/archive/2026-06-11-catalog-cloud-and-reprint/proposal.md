## Why

Dois problemas operacionais:

1. **Catálogo isolado por posto.** Hoje os produtos só sobem para o Firestore; nunca descem. Um SKU calibrado no posto A não aparece no posto B — cada bancada precisa recadastrar/recalibrar tudo. Falta puxar o catálogo da nuvem.
2. **Sem reimpressão.** Se uma etiqueta rasga, borra ou é perdida, não há como reimprimir a partir de um serial já validado. O operador fica sem saída.

## What Changes

- Baixar o catálogo de `products` do Firestore e fazer upsert no SQLite local (compartilha SKUs entre postos), mantendo o SQLite como fonte de verdade da operação.
- Disparar o pull manualmente (botão em Configurações) e automaticamente ao habilitar o sync.
- Buscar um serial já validado (busca local em `test_results`) e reimprimir sua etiqueta individual.

## Capabilities

### New Capabilities

- `catalog-cloud-pull`: Download e upsert do catálogo de produtos a partir do Firestore.

### Modified Capabilities

- `product-catalog`: O catálogo passa a poder ser semeado/atualizado por pull da nuvem (opt-in), sem deixar de funcionar offline.
- `label-printing`: Adiciona busca por serial e reimpressão individual de etiqueta.

## Impact

- **App Flutter** (`sirene_app/`):
  - Pull: mapper reverso `productFromFirestore`, `CatalogCloudService` (com `CatalogReader` injetável), provider, helper `pullCatalogFromCloud`, botão em `settings_screen.dart`, gancho em `setSyncEnabled`.
  - Reimpressão: `findTestResultBySerial`/`searchSerials` no banco, busca + botão "Reimprimir" em `labels_screen.dart`.
- **Firmware ESP32**: nenhuma alteração.
- **Firestore**: somente leitura da coleção `products` (regras já permitem leitura autenticada).
