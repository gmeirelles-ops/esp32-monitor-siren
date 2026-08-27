## MODIFIED Requirements

### Requirement: Navegação por papel (operador vs gestor)
A shell SHALL expor destinos distintos por papel. Operador SHALL ver **somente** `Lote` e `Gravação`. Gestor SHALL manter Painel, Relatório, Consulta, Gravação, Cadastros, Ensaio e Configurações (além de Lote). O app SHALL NOT exibir Consulta no menu do operador.

#### Scenario: Menu operador
- **WHEN** um operador (não gestor) autentica e entra na shell
- **THEN** a navegação mostra exatamente dois destinos: Lote e Gravação

#### Scenario: Menu gestor
- **WHEN** um gestor autentica
- **THEN** Consulta e Relatório permanecem acessíveis na navegação
