## ADDED Requirements

### Requirement: Persistência de falhas de hardware
O app SHALL persistir localmente cada falha de hardware recebida via MQTT (`alerta` com `falha`), registrando dispositivo, tipo de falha e instante.

#### Scenario: Falha de hardware registrada
- **WHEN** o app recebe um `alerta` com `falha` (evento que não seja de recuperação)
- **THEN** o app grava um evento de falha com `device_id`, `falha` e timestamp no SQLite

#### Scenario: Evento de recuperação não gera falha
- **WHEN** o app recebe um `alerta` de recuperação
- **THEN** o app não grava um novo evento de falha

### Requirement: Métricas de produção a partir do SQLite
O app SHALL calcular, a partir do histórico local de testes, o resumo de produção (total testado, aprovados, reprovados e yield), o throughput por dia e a contagem de falhas de hardware por tipo, filtráveis por período.

#### Scenario: Resumo de produção do período
- **WHEN** o supervisor seleciona um período no painel
- **THEN** o app exibe total testado, aprovados, reprovados e o yield (% aprovados) referentes ao período

#### Scenario: Throughput por dia
- **WHEN** o painel é exibido
- **THEN** o app mostra o volume testado por dia nos últimos dias, distinguindo aprovados do total

#### Scenario: Falhas de hardware por tipo
- **WHEN** existem falhas de hardware registradas no período
- **THEN** o app lista os tipos de falha com suas contagens, em ordem decrescente

### Requirement: Tela de painel de produção
O app SHALL oferecer uma tela "Painel" acessível pela navegação principal, exibindo as métricas de produção sem depender de conectividade com a nuvem.

#### Scenario: Acesso ao painel
- **WHEN** o usuário seleciona "Painel" na navegação
- **THEN** o app exibe os cartões de métricas e gráficos calculados a partir do SQLite local

#### Scenario: Sem dados no período
- **WHEN** não há resultados de teste no período selecionado
- **THEN** o painel indica ausência de dados em vez de exibir valores vazios ou erro
