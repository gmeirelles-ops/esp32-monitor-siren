# firestore-lote-serial-schema Specification

## Purpose
Esquema hierárquico Firestore para resultados de teste: lote (`test_results/{numero_op}`), seriais aprovados e reprovações, incluindo parâmetros de teste e espelhamento local SQLite.

## Requirements
### Requirement: Documento de lote em test_results
O Firestore SHALL armazenar metadados de cada OP no documento `test_results/{numero_op}` com campos: `numero_op`, `id_produto`, `ano`, `quantidade_total`, `device_id`, `status` (`active` | `completed`), `aprovados`, `reprovados`, `started_at`, `ended_at`, `station_id`, `tempo_teste_sec`, `potencia_min` e `potencia_max`.

#### Scenario: Lote iniciado na nuvem
- **WHEN** o app sincroniza um `SET_BATCH` bem-sucedido
- **THEN** existe documento `test_results/{numero_op}` com `status: "active"`, campos do lote preenchidos e parâmetros de teste (`tempo_teste_sec`, `potencia_min`, `potencia_max`)

#### Scenario: Lote encerrado na nuvem
- **WHEN** o app sincroniza `END_BATCH`
- **THEN** o documento `test_results/{numero_op}` recebe `status: "completed"` e `ended_at`

### Requirement: Subcoleção de seriais por lote
O Firestore SHALL armazenar cada sirene aprovada em `test_results/{numero_op}/seriais/{serial}`, onde `{serial}` é o serial ITF completo.

#### Scenario: Aprovação com serial e parâmetros de teste
- **WHEN** um teste aprovado com serial `1232600018` na OP `2026001` é sincronizado
- **THEN** existe documento `test_results/2026001/seriais/1232600018` com `sequencial`, `veredito`, `potencia_media`, `tempo_teste_sec`, `potencia_min`, `potencia_max`, `operador`, `operator_codigo` (quando disponível), `timestamp`, `device_id`, `station_id` e `is_retest`

#### Scenario: Consulta de seriais do lote no Console
- **WHEN** um administrador abre `test_results/2026001` no Firebase Console
- **THEN** a subcoleção `seriais` lista todos os números de série aprovados da OP com condições de teste registradas

### Requirement: Subcoleção reprovadas por lote
O Firestore SHALL armazenar cada teste reprovado em `test_results/{numero_op}/reprovadas/{sequencial}`, usando o sequencial do lote como document ID. Documentos em `reprovadas` SHALL NOT conter campo `serial`.

#### Scenario: Reprovação na OP com parâmetros
- **WHEN** um teste reprovado na OP `2026001` sequencial `3` é sincronizado
- **THEN** existe `test_results/2026001/reprovadas/3` com `veredito: "REPROVADO"`, `potencia_media`, `tempo_teste_sec`, `potencia_min`, `potencia_max`, `operador`, `timestamp`, `device_id` e `station_id`

#### Scenario: Idempotência por sequencial em reprovadas
- **WHEN** o mesmo teste reprovado `(numero_op, sequencial)` é reprocessado pela fila
- **THEN** o documento `reprovadas/{sequencial}` é sobrescrito sem duplicata

#### Scenario: reprovadas separada de seriais
- **WHEN** um teste é reprovado
- **THEN** nenhum documento é criado em `seriais/` para esse sequencial

### Requirement: Reteste reprovado na nuvem
O Firestore SHALL gravar retestes reprovados em `reprovadas/{sequencial}` com `is_retest: true`. Retestes aprovados SHALL NOT gerar documento em `seriais/` nem em `reprovadas/`.

#### Scenario: Reteste reprovado
- **WHEN** um reteste reprovado sequencial `5` é sincronizado
- **THEN** existe `test_results/{numero_op}/reprovadas/5` com `is_retest: true`

#### Scenario: Reteste aprovado
- **WHEN** um reteste aprovado é sincronizado
- **THEN** nenhum documento novo é criado em `seriais/` ou `reprovadas/` (apenas contadores no doc lote, se aplicável)

### Requirement: Persistência local dos parâmetros de teste
O SQLite SHALL armazenar `tempo_teste_sec`, `potencia_min`, `potencia_max` e `operator_id` em cada registro de `test_results` quando disponíveis no momento do teste.

#### Scenario: Teste gravado com lote ativo
- **WHEN** o app insere resultado de teste com lote ativo configurado
- **THEN** o registro local inclui os parâmetros de teste e o `operator_id` do operador autenticado

#### Scenario: Histórico anterior à migração
- **WHEN** um registro foi criado antes da migração de schema
- **THEN** os campos de parâmetros podem ser nulos e a UI exibe placeholder adequado

### Requirement: Busca de serial cross-lote
O projeto SHALL definir índice collection group em `seriais` permitindo localizar serial em qualquer lote.

#### Scenario: Serial encontrado em qualquer lote
- **WHEN** um consumidor externo consulta collection group `seriais` filtrando pelo serial exato
- **THEN** retorna o documento do lote correspondente
