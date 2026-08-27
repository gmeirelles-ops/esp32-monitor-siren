## ADDED Requirements

### Requirement: Operador pode ser cadastrado localmente

O sistema SHALL permitir cadastrar operadores com nome obrigatório, matrícula/código opcional e status ativo/inativo, persistidos em SQLite (Drift).

#### Scenario: Cadastro com sucesso

- **WHEN** o administrador preenche nome válido e confirma em Cadastros → Operadores
- **THEN** o operador é salvo localmente e aparece na lista de operadores ativos

#### Scenario: Nome duplicado

- **WHEN** o administrador tenta cadastrar operador com matrícula já existente
- **THEN** o sistema exibe erro de validação e não persiste o registro

### Requirement: Operador pode ser editado ou desativado

O sistema SHALL permitir editar nome/matrícula e desativar operadores sem apagar histórico de lotes já vinculados.

#### Scenario: Desativação

- **WHEN** o administrador desativa um operador
- **THEN** o operador deixa de aparecer na seleção do posto mas permanece referenciável em lotes históricos

### Requirement: Operadores sincronizam opcionalmente com Firestore

Quando sync de nuvem estiver habilitado, o sistema SHALL enfileirar operadores na `SyncQueue` para a coleção `operators/{id}`.

#### Scenario: Sync após cadastro

- **WHEN** sync está habilitado e um operador é criado ou atualizado
- **THEN** o registro é enfileirado e enviado ao Firestore quando online
