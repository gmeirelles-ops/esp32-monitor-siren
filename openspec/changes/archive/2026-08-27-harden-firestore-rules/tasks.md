## 1. Regras Firestore

- [ ] 1.1 Reescrever `firebase/firestore.rules` com imutabilidade de `test_results`, validação de `station_id`, read para autenticados
- [ ] 1.2 Revisar writes do app (`firestore_sync_service.dart`, `sync_queue_processor.dart`) contra novas regras

## 2. Testes de regras

- [ ] 2.1 Adicionar `scripts/test_firestore_rules` com Firebase Emulator
- [ ] 2.2 Casos: read ok, delete negado, write sem station_id negado, upsert ok

## 3. Documentação

- [ ] 3.1 Atualizar `docs/PRODUCAO.md` com política de usuários e claims (fase 2)
- [ ] 3.2 Documentar deploy: `firebase deploy --only firestore:rules`

## 4. Verificação

- [ ] 4.1 Sync end-to-end com app Windows e conta de teste
- [ ] 4.2 Confirmar que dead-letter não mascara rejeição por regras (`permission-denied`)
