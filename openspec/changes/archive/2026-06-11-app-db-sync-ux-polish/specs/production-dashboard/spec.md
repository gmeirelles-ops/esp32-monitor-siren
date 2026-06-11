## MODIFIED Requirements

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
