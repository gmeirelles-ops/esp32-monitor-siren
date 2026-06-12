## Why

O pull do catálogo Firestore faz upsert cego por `id_produto` — o último posto que sincroniza sobrescreve calibração e limites de potência sem aviso. Em ambiente multi-posto isso pode aplicar parâmetros errados na linha.

## What Changes

- Comparar produto local vs remoto campo a campo no pull.
- Detectar conflitos (valores diferentes em `potencia_min`, `potencia_max`, `calibrado_em`, etc.).
- UI de resolução: manter local, aceitar remoto, ou revisar por produto antes de aplicar.
- Registrar `updated_at` e `updated_by_station` no merge.
- Testes unitários de detecção de conflito.

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `catalog-cloud-pull`: merge com detecção e resolução de conflitos
- `product-catalog`: metadados de origem da última alteração

## Impact

- **App**: `catalog_cloud_service.dart`, tela Configurações ou modal pós-pull, possível coluna em `products` SQLite
