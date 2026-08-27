## Why

Todo o histórico de produção, catálogo, fila de sync e buffer de etiquetas vive no SQLite do PC Windows. Troca de máquina, corrupção de disco ou reinstalação do app sem backup implica perda de dados offline e dead-letters não sincronizados.

## What Changes

- Exportar backup completo do SQLite para arquivo `.zip` (banco + metadata JSON com versão schema e `station_id`).
- Restaurar backup com confirmação e validação de versão de schema.
- Ações em Configurações: "Fazer backup" e "Restaurar backup".
- Aviso se sync pendente antes de restaurar.

## Capabilities

### New Capabilities

- `local-backup`: backup e restore do banco SQLite local

### Modified Capabilities

- `flutter-app-shell`: ações de manutenção em Configurações

## Impact

- **App**: `database.dart`, `settings_screen.dart`, dependência `archive` para zip
- **Operação**: procedimento em `docs/PRODUCAO.md`
