## ADDED Requirements

### Requirement: App gestor desktop separado
O repositório SHALL incluir aplicativo Flutter `sirene_manager_app` destinado a gestores/supervisores, distinto do app operador `sirene_app`, com build Windows desktop.

#### Scenario: Instalação independente
- **WHEN** o gestor instala o app gestor no PC do escritório
- **THEN** o app abre sem exigir vínculo de bancada, MQTT ou login de operador PIN

#### Scenario: Identidade visual Diponto
- **WHEN** o gestor abre o app
- **THEN** o tema amber escuro segue a identidade Diponto alinhada ao app operador

### Requirement: Dashboard analítico conforme layout gestor
O app gestor SHALL exibir dashboard com filtros de período (Hoje / 7 dias / Tudo) e filtros opcionais por OP, produto e bancada, cards de KPI (Testado, Rendimento, Reprovados, Falhas HW), gráfico de throughput empilhado (testado vs aprovados), gráfico de rendimento diário com linha de meta, e tabela "Produção por lote" **sem coluna Ações**.

#### Scenario: Filtro 7 dias
- **WHEN** o gestor seleciona período "7 dias"
- **THEN** KPIs e gráficos refletem os últimos 7 dias civis e a tabela lista lotes com atividade no intervalo

#### Scenario: Tabela sem ações
- **WHEN** o dashboard gestor exibe "Produção por lote"
- **THEN** cada linha mostra OP, testes totais, aprovados, reprovados, rendimento % e status, sem ícones de editar/visualizar

#### Scenario: Status do lote
- **WHEN** um lote tem testes recentes e meta não atingida
- **THEN** o status exibido é "Em andamento" com estilo visual distinto de "Concluído" e "Revisar"

### Requirement: Dados via Firestore
O app gestor SHALL obter métricas exclusivamente por leitura no Firestore (dados sincronizados pelos postos operadores), sem conexão MQTT.

#### Scenario: Gestor autenticado
- **WHEN** o gestor faz login Firebase com permissão de leitura
- **THEN** o dashboard carrega agregações a partir de `test_results` e coleções relacionadas

#### Scenario: Sync desabilitado no posto
- **WHEN** nenhum posto enviou dados recentes ao Firestore
- **THEN** o dashboard exibe estado vazio ou aviso de dados desatualizados, sem erro fatal

### Requirement: Comparativos de KPI
Quando houver dados suficientes, os cards de KPI SHALL exibir variação percentual em relação ao período anterior equivalente (ex.: vs ontem para "Hoje", vs média para "7 dias").

#### Scenario: Testado vs ontem
- **WHEN** o período "Hoje" está selecionado e existem testes ontem e hoje
- **THEN** o card Testado exibe variação percentual vs ontem
