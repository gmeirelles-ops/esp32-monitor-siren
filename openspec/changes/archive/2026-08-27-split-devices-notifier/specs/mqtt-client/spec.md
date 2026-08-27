## ADDED Requirements

### Requirement: Organização modular do estado de dispositivos
O código do app que mantém o mapa de dispositivos MQTT SHALL ser organizado em módulos com responsabilidades distintas (inbound/FSM, lote, pipeline de teste/marcação, comandos auxiliares), sem alterar o comportamento observável das telas existentes.

#### Scenario: API pública estável
- **WHEN** as telas usam `devicesProvider` / métodos de lote e teste
- **THEN** as assinaturas e efeitos (SQLite, MarkQueue, MQTT publish) permanecem equivalentes

#### Scenario: Manutenibilidade
- **WHEN** um desenvolvedor precisa alterar só o enfileiramento laser pós-aprovação
- **THEN** o código vive em módulo/foco de pipeline de teste, não misturado com OTA/ensaio
