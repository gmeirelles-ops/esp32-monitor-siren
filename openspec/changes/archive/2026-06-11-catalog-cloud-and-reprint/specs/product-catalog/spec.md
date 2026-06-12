## MODIFIED Requirements

### Requirement: Catálogo local independente da nuvem na v1
O app SHALL NOT exigir leitura do Firestore para operar o catálogo — SQLite permanece a fonte de verdade no posto. O app MAY, de forma opt-in, baixar o catálogo da nuvem para semear ou atualizar o SQLite local.

#### Scenario: Primeiro uso sem internet
- **WHEN** o operador cadastra produtos com sync desabilitado ou sem conectividade
- **THEN** o catálogo funciona integralmente via SQLite e lotes podem ser configurados normalmente

#### Scenario: Semear catálogo a partir da nuvem
- **WHEN** o operador habilita o sync ou aciona o pull manual com Firebase disponível
- **THEN** o app baixa o catálogo da nuvem e faz upsert no SQLite, sem passar a depender da nuvem para a operação subsequente
