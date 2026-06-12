## ADDED Requirements

### Requirement: Harness de testes Flutter
O repositório SHALL fornecer utilitários de teste que permitem montar o app com banco SQLite in-memory, providers MQTT mockados e overrides Riverpod para widget tests.

#### Scenario: Widget test com banco in-memory
- **WHEN** um widget test usa o harness de teste
- **THEN** o app é montado sem acessar disco real nem conectar ao broker MQTT

#### Scenario: Override de providers
- **WHEN** o teste fornece overrides para `databaseProvider` ou `devicesProvider`
- **THEN** a tela sob teste consome os dados fake sem side effects de rede
