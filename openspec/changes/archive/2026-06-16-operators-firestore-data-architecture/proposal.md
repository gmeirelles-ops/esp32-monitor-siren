## Why

O app já tem login de operador com PIN e hierarquia Firestore `test_results/{lote}/seriais/{serial}`, mas três lacunas impedem o fluxo de produção desejado:

1. **Sessão persiste entre aberturas** — o operador anterior entra direto no shell sem reidentificação; o posto quer **login em toda inicialização** para rastreabilidade e troca de turno.
2. **Operadores só existem no SQLite local** — produtos já sincronizam com coleção `products` na nuvem; operadores precisam do mesmo padrão (cadastro centralizado, download no posto).
3. **Dados de teste incompletos na nuvem e local** — documentos de serial gravam `potencia_media` mas não `tempo_teste_sec`, `potencia_min` e `potencia_max` usados na bancada; relatórios externos não reproduzem as condições do teste.
4. **Reimpressão não respeita modo de marcação** — em modo laser, ações ainda falam em "reimprimir etiqueta"; o correto é **regravar** via fila laser.

## What Changes

- **BREAKING (comportamento):** ao iniciar o app, **sempre** exibir tela de login de operador; não restaurar sessão de operador de execuções anteriores (logout implícito ao fechar).
- Nova coleção Firestore **`operators/{codigo}`** espelhando cadastro local (`codigo` = PIN, `nome`, `ativo`, `updated_at`), com pull/push no mesmo fluxo de catálogo.
- Estender hierarquia `test_results`:
  - Documento lote: incluir `tempo_teste_sec`, `potencia_min`, `potencia_max` do lote ativo.
  - Subcoleção `seriais/{serial}`: incluir os mesmos campos + `potencia_media` por sirene.
  - Subcoleção `reprovadas/{sequencial}`: incluir parâmetros de teste da tentativa.
- Migração SQLite `test_results`: colunas opcionais `tempo_teste_sec`, `potencia_min`, `potencia_max` preenchidas no `insertTestResult` a partir do lote ativo.
- Ação unificada **Reimprimir / Regravar** conforme `MarkingMode` (etiquetas → ZPL; laser → `mark_queue` com `pinned`); rótulos e confirmações em português corretos em Etiquetas, Relatório de lote e busca por serial.
- Registrar **auditoria local** de reimpressão/regravação (`remark_log`: serial, operador, modo, timestamp).

### Sugestões adicionais incluídas neste change

| Sugestão | Escopo |
|----------|--------|
| `operator_id` em `test_results` (FK) além do texto `operador` | Rastreio estruturado; label derivado do cadastro |
| Botão **Baixar catálogo** puxa produtos **e** operadores | Um clique no posto |
| Exibir parâmetros de teste no detalhe do lote e export CSV | Supervisor vê tempo e faixa de potência |
| Regras Firestore para `operators/` | Mesmo padrão de `products/` |
| Logout explícito mantido em Configurações | Troca de operador sem fechar app |

### Fora de escopo (futuro)

- Hash de PIN (segurança reforçada) — PIN continua em texto no SQLite/Firestore neste change.
- Papéis supervisor vs operador com permissões distintas.
- Timeout de inatividade automático.

## Capabilities

### New Capabilities

- `firestore-operators-catalog`: coleção `operators`, sync bidirecional e pull integrado ao catálogo.
- `remark-by-marking-mode`: reimprimir etiqueta ou regravar laser conforme modo ativo, com auditoria.

### Modified Capabilities

- `operator-pin-login`: login obrigatório em **toda** abertura do app; sessão só válida na execução atual.
- `firestore-lote-serial-schema`: campos de parâmetros de teste no lote, seriais e reprovadas.
- `firestore-sync`: enfileirar novos campos; sync de operadores.
- `siren-traceability-report` / relatório por lote: exibir parâmetros de teste; ação remark por modo.

## Impact

- `sirene_app/lib/app.dart` — limpar operador no `initState` / startup
- `sirene_app/lib/core/config/app_config.dart` — não persistir `active_operator_id` (ou limpar sempre ao abrir)
- `sirene_app/lib/core/database/database.dart` — schema v14, `remark_log`, FK `operator_id`
- `sirene_app/lib/features/cloud/` — mappers, `CatalogCloudService`, `FirestoreSyncService`
- `sirene_app/lib/features/labels/labels_screen.dart`, `batch_report_detail_screen.dart` — remark unificado
- `sirene_app/lib/features/mqtt/mqtt_providers.dart` — gravar parâmetros de teste no insert/sync
- `firebase/firestore.rules` — regra `operators/{codigo}`
- Testes: `operators_test.dart`, `firestore_mappers_test.dart`, `catalog_cloud_test.dart`, widget remark
