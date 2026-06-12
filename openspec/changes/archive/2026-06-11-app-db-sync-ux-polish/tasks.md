## 1. Veredito e reconciliação

- [x] 1.1 Criar helper `isApprovedVeredito(String)` e usar em `productionSummary`, `throughputByDay` e `reconcileSerials`
- [x] 1.2 Teste unitário: reconciliação inclui veredito `aprovado` / `Aprovado`

## 2. Índices SQLite (schema v8)

- [x] 2.1 Migration v8: índices em `test_results(serial)`, `test_results(created_at)`, `sync_queue(attempts)`
- [x] 2.2 Rodar `dart run build_runner build` e validar migration em teste in-memory

## 3. Dead-letter Firestore

- [x] 3.1 Métodos `getFailedSyncItems()` e `resetSyncAttempts(id)` / `resetAllFailedSyncAttempts()` em `database.dart`
- [x] 3.2 UI em Configurações: listar falhas com `last_error` e botões "Tentar novamente"
- [x] 3.3 Teste unitário: reset zera attempts e item volta a pending

## 4. UI reativa

- [x] 4.1 `watchLabelBuffer()` e `watchLabelBufferCount()` — refatorar `LabelsScreen` para `StreamBuilder`/provider
- [x] 4.2 Provider de dashboard invalidado após insert de teste/falha HW — refatorar `DashboardScreen`
- [x] 4.3 Incrementar/invalidate revision no pipeline MQTT (`mqtt_providers.dart`)

## 5. ConnectionStatusBadge global

- [x] 5.1 Mover badge para `DipontoAppBar` (desktop + mobile)
- [x] 5.2 Remover duplicata em `DevicesScreen`

## 6. Verificação

- [x] 6.1 `flutter test` passando (incl. novos testes)
- [x] 6.2 Smoke manual documentado: painel atualiza após teste; dead-letter retry; badge visível em Etiquetas
