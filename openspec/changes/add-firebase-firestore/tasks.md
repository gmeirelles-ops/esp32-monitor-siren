## 1. Infraestrutura Firebase

- [ ] 1.1 Criar projeto Firebase `diponto-sirene` (ou nome acordado) e ativar Firestore Standard em `southamerica-east1`
- [x] 1.2 Adicionar `firebase.json`, `firebase/firestore.rules` e `firebase/firestore.indexes.json` na raiz do repositório
- [ ] 1.3 Criar contas de operador no Firebase Console (e-mail/senha)
- [ ] 1.4 Executar `flutterfire configure` em `sirene_app/` e commitar `lib/firebase_options.dart` (stub presente; substituir após configure)
- [ ] 1.5 Deploy inicial: `firebase deploy --only firestore`

## 2. Dependências e bootstrap

- [x] 2.1 Adicionar `firebase_core`, `cloud_firestore`, `firebase_auth` ao `pubspec.yaml`
- [x] 2.2 Criar `lib/features/cloud/firebase_bootstrap.dart` com init condicional (graceful se options ausentes)
- [x] 2.3 Habilitar `Settings.persistenceEnabled = true` no Firestore
- [x] 2.4 Atualizar `main.dart` para inicializar Firebase antes de `runApp`

## 3. Autenticação

- [x] 3.1 Implementar `AuthService` com login, logout e stream de auth state
- [x] 3.2 Criar `auth_providers.dart` (Riverpod) expondo `authState`, `isAuthenticated`
- [x] 3.3 Criar `login_screen.dart` com e-mail, senha e mensagens de erro em português
- [x] 3.4 Integrar gate: toggle de sync só habilita com sessão ativa

## 4. Banco local — fila de sincronização

- [x] 4.1 Adicionar tabela `SyncQueue` no Drift (schema v3) com migração
- [x] 4.2 Implementar métodos: `enqueueSync`, `getPendingItems`, `markSynced`, `markFailed`, `countPending`
- [x] 4.3 Rodar `dart run build_runner build` para regenerar `database.g.dart`

## 5. Serviço de sincronização

- [x] 5.1 Criar `firestore_mappers.dart` (MQTT/SQLite → Map Firestore por coleção)
- [x] 5.2 Implementar `FirestoreSyncService` com métodos `enqueueTestResult`, `enqueueDeviceUpdate`, `enqueueBatch`, `enqueueProduct`
- [x] 5.3 Implementar debounce de 60 s para `devices/{device_id}`
- [x] 5.4 Implementar `SyncQueueProcessor` com timer 30 s, FIFO, backoff (máx 5 tentativas)
- [x] 5.5 Criar `sync_providers.dart` com toggle de sync, `station_id`, status (último sync, pendências, falhas)

## 6. Hooks nos fluxos existentes

- [x] 6.1 `mqtt_providers.dart`: após `insertTestResult`, chamar `enqueueTestResult`
- [x] 6.2 `mqtt_providers.dart`: em heartbeat, chamar `enqueueDeviceUpdate` (com debounce)
- [x] 6.3 `mqtt_providers.dart`: em LWT offline, chamar `enqueueDeviceUpdate(online: false)` imediato
- [x] 6.4 `mqtt_providers.dart`: em `setActiveBatch`/`endBatch`, chamar `enqueueBatch`
- [x] 6.5 `products_provider.dart`: após upsert/recalibração, chamar `enqueueProduct`

## 7. UI — Configurações e login

- [x] 7.1 Adicionar seção "Nuvem" em Configurações: toggle sync, `station_id`, status da fila, logout
- [x] 7.2 Persistir `station_id` e `syncEnabled` em SharedPreferences (sync desabilitado por padrão)
- [x] 7.3 Navegar para login quando operador tenta habilitar sync sem sessão
- [x] 7.4 Manter acesso às telas locais sem autenticação

## 8. Testes

- [x] 8.1 Teste unitário: mapeamento `test_results` com chave `numero_op_sequencial`
- [x] 8.2 Teste unitário: debounce de device update (60 s)
- [x] 8.3 Teste unitário: fila SQLite enqueue/drain com mock Firestore
- [x] 8.4 Teste widget: login screen validação de campos
- [x] 8.5 `flutter analyze` e `flutter test` passando

## 9. Documentação e validação

- [x] 9.1 Atualizar `GUIA_COMPLETO.md` §16 com status "implementado" e passos de setup
- [x] 9.2 Atualizar `docs/PRODUCAO.md` com checklist Firebase (projeto, contas, deploy rules, flutterfire)
- [x] 9.3 Validar `flutter build windows --release` com Firebase habilitado (validado `flutter build linux --release` neste ambiente)
- [ ] 9.4 Smoke test ponta a ponta: login → habilitar sync → teste MQTT → documento em Firestore Console
