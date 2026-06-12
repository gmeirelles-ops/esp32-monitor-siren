# production-dashboard Specification

## Purpose
Painel analítico no app Flutter: métricas de produção, throughput e falhas de hardware calculados a partir do SQLite local, sem dependência de nuvem.
## Requirements
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
O app SHALL oferecer uma tela "Painel" acessível pela navegação principal, exibindo as métricas de produção sem depender de conectividade com a nuvem, atualizando automaticamente quando novos testes ou falhas de hardware são gravados localmente.

#### Scenario: Acesso ao painel
- **WHEN** o usuário seleciona "Painel" na navegação
- **THEN** o app exibe os cartões de métricas e gráficos calculados a partir do SQLite local

#### Scenario: Sem dados no período
- **WHEN** não há resultados de teste no período selecionado
- **THEN** o painel indica ausência de dados em vez de exibir valores vazios ou erro

#### Scenario: Atualização após novo teste
- **WHEN** um resultado de teste é gravado no SQLite enquanto o Painel está visível
- **THEN** as métricas e gráficos do período selecionado são atualizados sem exigir troca de aba ou recarga manual

### Requirement: Feed de alertas de hardware recentes
O painel SHALL exibir um feed dos alertas de hardware mais recentes registrados localmente, para que o supervisor possa agir sobre falhas.

#### Scenario: Alertas recentes listados
- **WHEN** existem falhas de hardware registradas
- **THEN** o painel lista os alertas mais recentes com dispositivo, tipo de falha e instante

#### Scenario: Sem alertas
- **WHEN** não há falhas de hardware registradas
- **THEN** o painel indica que não há alertas recentes

