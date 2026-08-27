## MODIFIED Requirements

### Requirement: Amostras de calibração usam fila offline

O firmware SHALL enfileirar amostras `calibracao_amostra` via `publish_or_queue` quando MQTT estiver desconectado, igual ao resultado final de calibração.

#### Scenario: Calibração sem broker

- **WHEN** calibração está em andamento e MQTT está offline
- **THEN** amostras são persistidas na fila SPIFFS e republicadas em `calibracao` após reconexão

## REMOVED Requirements

### Requirement: Amostras de calibração descartadas offline

**Reason:** Inconsistente com política offline-first do restante do firmware.

**Migration:** Nenhuma — comportamento estrito melhor; app pode receber burst de amostras após reconexão.
