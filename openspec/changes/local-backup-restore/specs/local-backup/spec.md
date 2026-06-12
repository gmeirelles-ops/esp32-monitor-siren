## ADDED Requirements

### Requirement: Exportação de backup local
O app SHALL permitir exportar um arquivo de backup contendo o banco SQLite e metadados de versão para armazenamento externo.

#### Scenario: Backup manual
- **WHEN** o operador aciona "Fazer backup" nas Configurações
- **THEN** o app grava um arquivo ZIP com o banco e manifest incluindo versão do schema e `station_id`

### Requirement: Restauração de backup local
O app SHALL permitir restaurar o banco a partir de um arquivo de backup válido, substituindo os dados locais após confirmação explícita.

#### Scenario: Restore bem-sucedido
- **WHEN** o operador seleciona um backup compatível e confirma a restauração
- **THEN** o app substitui o SQLite local e reinicia o estado da aplicação com os dados do backup

#### Scenario: Backup incompatível
- **WHEN** o schema do backup é mais novo que o suportado pelo app instalado
- **THEN** o app recusa a restauração e orienta atualizar o aplicativo

#### Scenario: Restore com fila pendente
- **WHEN** existem entradas pendentes na SyncQueue e o operador inicia restore
- **THEN** o app alerta sobre perda de pendências não sincronizadas antes de prosseguir
