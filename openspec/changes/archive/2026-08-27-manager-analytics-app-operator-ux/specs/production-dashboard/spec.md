## MODIFIED Requirements

### Requirement: Tela de painel de produção
O app operador SHALL NOT expor o painel analítico completo (gráficos de throughput, yield por dia, tabela de produção por lote com status). Essas capacidades SHALL ser atendidas pelo app gestor `sirene_manager_app` via Firestore. O operador pode manter apenas persistência local de testes e falhas para sync.

#### Scenario: Navegação sem Painel analítico
- **WHEN** o operador autenticado usa o menu principal
- **THEN** não há destino "Painel" com gráficos e KPIs analíticos

#### Scenario: Dados locais continuam disponíveis para sync
- **WHEN** testes e falhas são gravados no SQLite do posto
- **THEN** a fila de sync pode enviar os mesmos dados ao Firestore para o app gestor

### Requirement: Resumo de produção por lote no período
A tabela e visão analítica "Produção por lote" com status (Concluído / Revisar / Em andamento) SHALL ser implementada no app gestor, não no app operador.

#### Scenario: Gestor vê produção por lote
- **WHEN** o gestor abre o dashboard no `sirene_manager_app`
- **THEN** a tabela de lotes é exibida conforme filtros, sem coluna Ações
