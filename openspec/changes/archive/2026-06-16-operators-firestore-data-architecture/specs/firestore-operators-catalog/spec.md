## ADDED Requirements

### Requirement: Coleção operators no Firestore
O Firestore SHALL armazenar operadores na coleção `operators/{codigo}`, onde `{codigo}` é o PIN do operador.

#### Scenario: Documento de operador
- **WHEN** um operador com código `1234` e nome `Maria` é sincronizado
- **THEN** existe documento `operators/1234` com campos `codigo`, `nome`, `ativo` e `updated_at`

### Requirement: Pull de operadores da nuvem
O app SHALL baixar operadores da coleção `operators` e aplicar no SQLite local quando o usuário acionar baixar catálogo ou ao habilitar sync.

#### Scenario: Download com operadores na nuvem
- **WHEN** o usuário autenticado no Firebase aciona "Baixar catálogo" e existem documentos em `operators`
- **THEN** os operadores são inseridos ou atualizados no SQLite e aparecem na tela de login

#### Scenario: Merge por updated_at
- **WHEN** um operador local e remoto compartilham o mesmo `codigo` e o remoto tem `updated_at` mais recente
- **THEN** o registro local é atualizado com os dados da nuvem

### Requirement: Push de operadores para a nuvem
O app SHALL enviar alterações de operadores locais para `operators/{codigo}` quando sync estiver habilitado e o usuário estiver autenticado no Firebase.

#### Scenario: Novo operador cadastrado com sync ativo
- **WHEN** um supervisor cadastra operador ativo com sync habilitado
- **THEN** o documento correspondente é criado ou atualizado em `operators/{codigo}`

### Requirement: Operadores inativos omitidos na login
Operadores com `ativo: false` SHALL NOT aparecer na lista da tela de login após pull ou edição local.

#### Scenario: Operador desativado na nuvem
- **WHEN** pull traz operador com `ativo: false`
- **THEN** o operador não é listado na tela de login

### Requirement: Regras Firestore para operators
As regras Firestore SHALL permitir leitura e escrita em `operators/{codigo}` para usuários autenticados, no mesmo padrão de `products`.

#### Scenario: Escrita autenticada
- **WHEN** um cliente autenticado envia upsert em `operators/5678`
- **THEN** a operação é permitida

#### Scenario: Leitura sem autenticação
- **WHEN** um cliente não autenticado tenta ler `operators`
- **THEN** a operação é negada
