## ADDED Requirements

### Requirement: Agregação de métricas de produção no Firestore
O sistema SHALL suportar consultas que agregam, por intervalo de tempo e filtros opcionais (OP, `id_produto`, `station_id`/bancada), total testado, aprovados, reprovados, yield %, throughput diário e contagem de falhas de hardware.

#### Scenario: Agregação por dia
- **WHEN** o gestor solicita throughput dos últimos 7 dias
- **THEN** o sistema retorna, para cada dia, total de testes e total de aprovados

#### Scenario: Filtro por produto
- **WHEN** o gestor filtra por `id_produto`
- **THEN** todas as agregações consideram apenas documentos daquele produto

#### Scenario: Resumo por OP
- **WHEN** nenhum filtro de OP está ativo
- **THEN** o sistema retorna lista de OPs com testes no período, cada uma com totais, aprovados, reprovados e rendimento

### Requirement: Índices Firestore para analytics
O projeto SHALL definir índices compostos necessários para queries de analytics por `timestamp`, `station_id`, `numero_op` e `id_produto` sem erro `failed-precondition`.

#### Scenario: Query filtrada por período e posto
- **WHEN** o app gestor consulta testes dos últimos 7 dias de um `station_id`
- **THEN** a query executa com índice documentado em `firestore.indexes.json`

### Requirement: Permissão de leitura para gestores
As regras Firestore SHALL permitir leitura de `test_results`, `products` e `operators` a usuários com role gestor, sem conceder escrita nos dados de produção.

#### Scenario: Gestor lê test_results
- **WHEN** usuário autenticado com claim `manager` consulta `test_results`
- **THEN** a leitura é permitida

#### Scenario: Gestor não grava test_results
- **WHEN** usuário gestor tenta criar ou alterar `test_results`
- **THEN** a operação é negada
