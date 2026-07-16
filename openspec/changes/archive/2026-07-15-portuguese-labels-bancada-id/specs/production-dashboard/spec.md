## ADDED Requirements

### Requirement: Rendimento no painel de produção
O painel de produção SHALL rotular o percentual de aprovação como "Rendimento" em gráficos, cartões e exportações derivadas do painel.

#### Scenario: Cartão de resumo
- **WHEN** o painel exibe resumo do período
- **THEN** o campo percentual aparece como "Rendimento" e não "Yield"

#### Scenario: Gráfico por dia
- **WHEN** o gráfico de série temporal é exibido
- **THEN** o eixo ou legenda usa "Rendimento (%)" em português
