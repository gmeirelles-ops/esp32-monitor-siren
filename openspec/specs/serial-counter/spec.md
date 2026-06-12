# serial-counter Specification

## Purpose
Contador de serial por produto e ano no app Flutter, com reconciliação contra resultados de teste aprovados no SQLite local.
## Requirements
### Requirement: Contador persistente de sequencial por produto e ano
O app SHALL manter um contador persistente do último sequencial utilizado por combinação `(id_produto, ano)`, atualizado a cada serial aprovado emitido localmente.

#### Scenario: Contador atualizado em aprovação
- **WHEN** um teste é APROVADO e um serial é gerado para `(id_produto, ano, sequencial)`
- **THEN** o contador de `(id_produto, ano)` é atualizado para o maior valor entre o atual e o `sequencial` emitido

#### Scenario: Contador sobrevive a reinício
- **WHEN** o app é fechado e reaberto
- **THEN** o último sequencial por `(id_produto, ano)` permanece disponível a partir do armazenamento local

### Requirement: Sugestão automática do próximo sequencial
O app SHALL sugerir o `proximo_sequencial` no formulário de lote como `último utilizado + 1` para o `(id_produto, ano)` selecionado, ou `1` quando não houver histórico.

#### Scenario: Produto com histórico
- **WHEN** o operador seleciona um produto/ano que já possui seriais emitidos
- **THEN** o campo `proximo_sequencial` é pré-preenchido com o último sequencial conhecido mais um

#### Scenario: Produto sem histórico
- **WHEN** o operador seleciona um produto/ano sem seriais emitidos
- **THEN** o campo `proximo_sequencial` é pré-preenchido com `1`

### Requirement: Trava anti-duplicado na emissão de serial
O app SHALL verificar a existência de um serial antes de emiti-lo; se o serial já existir localmente, o app SHALL NOT adicioná-lo ao buffer de etiquetas e SHALL sinalizar o conflito ao operador.

#### Scenario: Serial inédito
- **WHEN** um teste aprovado gera um serial que não existe no histórico local
- **THEN** o serial é adicionado ao buffer de etiquetas normalmente

#### Scenario: Serial duplicado
- **WHEN** um teste aprovado gera um serial que já existe no histórico local
- **THEN** o app não adiciona o serial ao buffer e exibe um alerta de duplicidade ao operador

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

