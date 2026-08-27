# local-backup Specification

## Purpose
Backup e restore offline do SQLite do posto (ZIP com banco, manifest e prefs operacionais).
## Requirements
### Requirement: Exportar backup ZIP do posto
O app SHALL permitir exportar um arquivo ZIP contendo o SQLite local, um `manifest.json` com `schemaVersion`, `stationId`, `appVersion`, `createdAt` e `formatVersion`, e um `prefs.json` com preferências operacionais (MQTT, laser, station/setup).

#### Scenario: Backup bem-sucedido
- **WHEN** o gestor aciona "Fazer backup" e escolhe o destino
- **THEN** o app gera um ZIP legível e exibe confirmação de sucesso

### Requirement: Restaurar backup com validação
O app SHALL restaurar um ZIP de backup após confirmação explícita, recusando se `schemaVersion` do backup for maior que o schema do app em execução.

#### Scenario: Schema incompatível (backup mais novo)
- **WHEN** o operador seleciona um ZIP cujo `schemaVersion` > schema do app
- **THEN** o app rejeita o restore e orienta atualizar o aplicativo

#### Scenario: Confirmação
- **WHEN** o operador inicia restore
- **THEN** deve confirmar digitando `RESTAURAR` antes de sobrescrever o banco

### Requirement: Aviso de sync pendente
Antes de restaurar, o app SHALL informar se existem itens pendentes na SyncQueue.

#### Scenario: Fila não vazia
- **WHEN** há N > 0 pendências de sync e o operador inicia restore
- **THEN** o diálogo exibe o número de pendências e permite cancelar
