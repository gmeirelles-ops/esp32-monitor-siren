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
O app SHALL calcular, a partir do histórico local de testes, o resumo de produção (total testado, aprovados, reprovados e yield), o throughput por dia e a contagem de falhas de hardware por tipo, filtráveis por período **e opcionalmente por OP (lote), produto (`id_produto`) e dispositivo**.

#### Scenario: Resumo de produção do período
- **WHEN** o supervisor seleciona um período no painel
- **THEN** o app exibe total testado, aprovados, reprovados e o yield (% aprovados) referentes ao período

#### Scenario: Resumo com filtro de lote
- **WHEN** o supervisor seleciona uma OP específica nos filtros do painel
- **THEN** todas as métricas e gráficos refletem apenas testes daquela OP no período selecionado

#### Scenario: Resumo com filtro de produto
- **WHEN** o supervisor seleciona um `id_produto` nos filtros
- **THEN** as métricas consideram apenas testes daquele produto no período

#### Scenario: Throughput por dia
- **WHEN** o painel é exibido
- **THEN** o app mostra o volume testado por dia no intervalo do período selecionado, distinguindo aprovados do total

#### Scenario: Falhas de hardware por tipo
- **WHEN** existem falhas de hardware registradas no período
- **THEN** o app lista os tipos de falha com suas contagens, em ordem decrescente, respeitando os filtros de período aplicáveis

### Requirement: Tela de painel de produção
O app SHALL oferecer uma tela "Painel" acessível pela navegação principal, exibindo as métricas de produção sem depender de conectividade com a nuvem, atualizando automaticamente quando novos testes ou falhas de hardware são gravados localmente, **com filtros combináveis e gráficos aprimorados**.

#### Scenario: Acesso ao painel
- **WHEN** o usuário seleciona "Painel" na navegação
- **THEN** o app exibe os cartões de métricas e gráficos calculados a partir do SQLite local

#### Scenario: Filtros combináveis visíveis
- **WHEN** o painel é aberto
- **THEN** o app exibe controles de período (Hoje / 7 dias / Tudo) e filtros opcionais por OP, produto e dispositivo

#### Scenario: Limpar filtros
- **WHEN** o supervisor limpa os filtros de OP, produto ou dispositivo
- **THEN** o painel volta a exibir dados agregados de todos os lotes/produtos/dispositivos no período

#### Scenario: Sem dados no período
- **WHEN** não há resultados de teste no período e filtros selecionados
- **THEN** o painel indica ausência de dados em vez de exibir valores vazios ou erro

#### Scenario: Atualização após novo teste
- **WHEN** um resultado de teste é gravado no SQLite enquanto o Painel está visível
- **THEN** as métricas e gráficos do período e filtros selecionados são atualizados sem exigir troca de aba ou recarga manual

### Requirement: Feed de alertas de hardware recentes
O painel SHALL exibir um feed dos alertas de hardware mais recentes registrados localmente, para que o supervisor possa agir sobre falhas.

#### Scenario: Alertas recentes listados
- **WHEN** existem falhas de hardware registradas
- **THEN** o painel lista os alertas mais recentes com dispositivo, tipo de falha e instante

#### Scenario: Sem alertas
- **WHEN** não há falhas de hardware registradas
- **THEN** o painel indica que não há alertas recentes

### Requirement: Gráfico de yield por dia
O painel SHALL exibir gráfico de yield (%) por dia no intervalo do período filtrado.

#### Scenario: Yield visível na semana
- **WHEN** o período "7 dias" está selecionado e há testes em dias distintos
- **THEN** o painel exibe barras ou pontos com yield percentual por dia

#### Scenario: Dia sem testes
- **WHEN** um dia no intervalo não possui testes
- **THEN** o gráfico indica zero ou omite a barra daquele dia sem erro

### Requirement: Resumo de produção por lote no período
Quando nenhuma OP específica está selecionada no filtro, o painel SHALL exibir visão resumida por lote (OP) no período, com total testado, aprovados e yield por OP.

#### Scenario: Múltiplos lotes no período
- **WHEN** existem testes de três OPs distintas no período filtrado
- **THEN** o painel lista ou grafica as três OPs com suas métricas individuais

#### Scenario: Filtro de OP ativo oculta resumo por lote
- **WHEN** o supervisor filtra por uma OP específica
- **THEN** a seção de resumo por lote não é exibida (métricas já são da OP selecionada)

### Requirement: Legenda e legibilidade dos gráficos
Os gráficos do painel SHALL incluir legenda distinguindo total testado e aprovados, com rótulos de eixo legíveis e cores consistentes com o tema do app.

#### Scenario: Throughput com legenda
- **WHEN** o gráfico de throughput por dia é exibido
- **THEN** o operador identifica visualmente a parcela aprovada dentro do total de cada dia

#### Scenario: Rótulos de data
- **WHEN** o gráfico cobre mais de um dia
- **THEN** cada barra ou ponto exibe rótulo de data (dia/mês) sem sobreposição ilegível em telas desktop

