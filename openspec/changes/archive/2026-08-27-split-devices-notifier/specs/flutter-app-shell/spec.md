## ADDED Requirements

### Requirement: Sem regressão de UX no shell
A navegação e fluxos do posto (Lote, Painel, Gravação, Configurações) SHALL continuar funcionando após a reorganização interna do `DevicesNotifier`.

#### Scenario: Smoke pós-refator
- **WHEN** a suíte `flutter test` é executada
- **THEN** os testes de MQTT/lote/serial/marcação existentes passam
