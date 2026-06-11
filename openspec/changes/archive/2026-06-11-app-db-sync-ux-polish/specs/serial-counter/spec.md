## MODIFIED Requirements

### Requirement: Reconciliação de sequência de lote
O app SHALL oferecer reconciliação que, para um `(id_produto, ano)`, identifique buracos (sequenciais ausentes) e duplicatas na sequência de seriais aprovados, tratando veredito de forma case-insensitive de modo consistente com as métricas de produção.

#### Scenario: Sequência íntegra
- **WHEN** o operador consulta a reconciliação de um produto/ano cujos sequenciais aprovados são contíguos e únicos
- **THEN** o app indica que não há buracos nem duplicatas

#### Scenario: Sequência com buraco
- **WHEN** existe um sequencial ausente entre o menor e o maior aprovados
- **THEN** o app lista o(s) sequencial(is) faltante(s)

#### Scenario: Sequência com duplicata
- **WHEN** dois ou mais seriais aprovados compartilham o mesmo sequencial
- **THEN** o app lista o sequencial duplicado

#### Scenario: Veredito em caixa alternativa
- **WHEN** um resultado está gravado com veredito `aprovado` ou `Aprovado` (variação de caixa) e serial válido
- **THEN** a reconciliação inclui esse registro na sequência de aprovados, igual às métricas do painel
