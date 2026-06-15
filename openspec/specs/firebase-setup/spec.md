# firebase-setup Specification

## Purpose
Configuração e bootstrap do SDK Firebase no app Flutter e infraestrutura versionada no monorepo para deploy reproduzível de regras e índices Firestore.
## Requirements
### Requirement: Inicialização do SDK Firebase no app
O app SHALL inicializar o Firebase Core antes de `runApp`, usando as opções geradas por FlutterFire (`firebase_options.dart`) para a plataforma em execução.

#### Scenario: App inicia com Firebase configurado
- **WHEN** o app é aberto em Windows ou Android com `firebase_options.dart` presente
- **THEN** `Firebase.initializeApp` completa sem erro e os serviços Firebase ficam disponíveis para os providers

#### Scenario: Firebase não configurado em build de desenvolvimento
- **WHEN** `firebase_options.dart` não existe (build sem FlutterFire)
- **THEN** o app inicia normalmente com sincronização em nuvem desabilitada e mensagem informativa nas Configurações

### Requirement: Dependências Firebase no projeto Flutter
O `pubspec.yaml` SHALL incluir `firebase_core`, `cloud_firestore` e `firebase_auth` nas versões compatíveis com o SDK Flutter atual do projeto.

#### Scenario: Resolução de dependências
- **WHEN** o desenvolvedor executa `flutter pub get`
- **THEN** as dependências Firebase resolvem sem conflito com pacotes existentes (Drift, Riverpod, mqtt_client)

### Requirement: Arquivos de configuração Firebase versionados
O repositório SHALL conter `firebase.json`, `firebase/firestore.rules` e `firebase/firestore.indexes.json` na raiz do monorepo, permitindo deploy reproduzível das regras e índices incluindo a hierarquia `test_results/{lote}/seriais/{serial}`.

#### Scenario: Deploy de regras
- **WHEN** o administrador executa `firebase deploy --only firestore` na raiz do repositório
- **THEN** as security rules e índices (incluindo subcoleções de `test_results`) são aplicados ao projeto Firebase configurado

### Requirement: Persistência offline do cliente Firestore
O app SHALL habilitar a cache de persistência local do Firestore (`Settings.persistenceEnabled = true`) para que escritas enfileiradas pelo SDK sejam retentadas automaticamente quando a rede retornar.

#### Scenario: Escrita com rede indisponível
- **WHEN** o sync service tenta gravar no Firestore sem conectividade
- **THEN** a operação é enfileirada pela cache do SDK e concluída automaticamente ao reconectar, sem perda de dados na fila local

### Requirement: Regras Firestore para hierarquia test_results
O arquivo `firebase/firestore.rules` SHALL permitir leitura e escrita autenticada em `test_results/{numeroOp}` e em todas as subcoleções descendentes (`seriais`, `reprovadas`). Writes em subcoleções SHALL exigir `station_id` não vazio no payload.

#### Scenario: Write de serial autenticado
- **WHEN** um usuário autenticado grava `test_results/2026001/seriais/1232600018` com `station_id` válido
- **THEN** a operação é permitida

#### Scenario: Write sem station_id
- **WHEN** um write em `test_results/{numeroOp}/reprovadas/{sequencial}` não contém `station_id`
- **THEN** a operação é rejeitada

#### Scenario: Delete bloqueado
- **WHEN** um usuário autenticado tenta `delete` em `test_results/{numeroOp}/seriais/{serial}`
- **THEN** a operação é rejeitada

### Requirement: Índices Firestore para subcoleções
O arquivo `firebase/firestore.indexes.json` SHALL incluir índice collection group para subcoleção `seriais` quando necessário para consultas cross-lote por serial ou `station_id`.

#### Scenario: Deploy de índices
- **WHEN** o administrador executa `firebase deploy --only firestore:indexes`
- **THEN** índices para `seriais` (collection group) são criados sem erro

