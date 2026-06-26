## 1. Login em toda abertura

- [x] 1.1 Limpar `active_operator_id` no startup (`AppGate`) antes de avaliar sessão
- [x] 1.2 Manter operador apenas em memória durante execução (`setActiveOperator` sem persistir ou persistência ignorada no boot)
- [x] 1.3 Atualizar testes/widget: reabertura simulada exige login; troca de operador em Configurações continua funcionando
- [x] 1.4 Atualizar spec `operator-pin-login` — remover cenário de sessão restaurada

## 2. Schema SQLite v14

- [x] 2.1 Adicionar colunas `tempo_teste_sec`, `potencia_min`, `potencia_max`, `operator_id` em `test_results`
- [x] 2.2 Criar tabela `remark_log` (serial, numero_op, mode, operator_id, created_at)
- [x] 2.3 Migração Drift v13 → v14 com backfill nullable
- [x] 2.4 Preencher novos campos em `insertTestResult` a partir de `BatchConfig` e operador ativo

## 3. Firestore — parâmetros de teste

- [x] 3.1 Estender `mapLoteDocument`, `mapSerialDocument`, `mapReprovadaDocument` com tempo/potência
- [x] 3.2 Passar parâmetros de teste em `enqueueTestResult` / `FirestoreSyncService`
- [x] 3.3 Incluir `operator_codigo` nos documentos de serial e reprovada
- [x] 3.4 Testes em `firestore_mappers_test.dart` para novos campos

## 4. Coleção operators na nuvem

- [x] 4.1 Adicionar `mapOperator` / `operatorFromFirestore` em `firestore_mappers.dart`
- [x] 4.2 Implementar pull de `operators` em `CatalogCloudService` (ou serviço dedicado)
- [x] 4.3 Implementar push/sync de operadores ao salvar/editar no cadastro local
- [x] 4.4 Unificar `pullCatalogFromCloud` — produtos + operadores; mensagem na UI
- [x] 4.5 Adicionar regra `match /operators/{codigo}` em `firebase/firestore.rules`
- [x] 4.6 Testes em `catalog_cloud_test.dart` para operadores

## 5. Remark por modo de marcação

- [x] 5.1 Criar `remark_serial.dart` (ou serviço equivalente) unificando ZPL vs fila laser
- [x] 5.2 Atualizar busca por serial em `labels_screen.dart` — rótulos e ícones por modo
- [x] 5.3 Atualizar `batch_report_detail_screen.dart` — remark por modo
- [x] 5.4 Registrar `remark_log` após cada remark
- [x] 5.5 Testes unitários para ramificação labels/laser

## 6. Relatórios e UI

- [x] 6.1 Exibir tempo de teste e faixa de potência no detalhe do lote
- [x] 6.2 Incluir colunas opcionais no export CSV de lote
- [x] 6.3 Atualizar `docs/PRODUCAO.md` — login obrigatório, catálogo operadores, remark laser

## 7. Validação

- [x] 7.1 `flutter test` nos arquivos alterados
- [ ] 7.2 Smoke manual: abrir app → login → teste → verificar Firestore serial com tempo/potência
- [ ] 7.3 Smoke manual: modo laser → buscar serial → regravar → F2
