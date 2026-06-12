## ADDED Requirements

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
O repositório SHALL conter `firebase.json`, `firebase/firestore.rules` e `firebase/firestore.indexes.json` na raiz do monorepo, permitindo deploy reproduzível das regras e índices.

#### Scenario: Deploy de regras
- **WHEN** o administrador executa `firebase deploy --only firestore` na raiz do repositório
- **THEN** as security rules e índices são aplicados ao projeto Firebase configurado

### Requirement: Persistência offline do cliente Firestore
O app SHALL habilitar a cache de persistência local do Firestore (`Settings.persistenceEnabled = true`) para que escritas enfileiradas pelo SDK sejam retentadas automaticamente quando a rede retornar.

#### Scenario: Escrita com rede indisponível
- **WHEN** o sync service tenta gravar no Firestore sem conectividade
- **THEN** a operação é enfileirada pela cache do SDK e concluída automaticamente ao reconectar, sem perda de dados na fila local
