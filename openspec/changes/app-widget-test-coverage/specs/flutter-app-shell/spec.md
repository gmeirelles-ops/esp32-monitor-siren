## MODIFIED Requirements

### Requirement: Cobertura de testes das telas principais
O app SHALL incluir widget tests automatizados para as telas Lote, Etiquetas, Painel e Configurações, verificando renderização em estado vazio e com dados mockados mínimos.

#### Scenario: Tela Lote em estado vazio
- **WHEN** o widget test monta `BatchScreen` sem lote ativo
- **THEN** a tela exibe estado inicial esperado sem exceções

#### Scenario: Tela Etiquetas com buffer
- **WHEN** o widget test monta `LabelsScreen` com itens no buffer mockado
- **THEN** a lista de etiquetas é exibida

#### Scenario: CI executa widget tests
- **WHEN** o pipeline de CI roda `flutter test`
- **THEN** os widget tests das telas principais são incluídos e devem passar
