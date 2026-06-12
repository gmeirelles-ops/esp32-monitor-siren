## ADDED Requirements

### Requirement: Fila cheia gera rejeição MQTT

O firmware SHALL publicar `{"tipo":"rejeicao","motivo":"fila_cheia"}` quando `xQueueSend` para a fila de trabalho MQTT falhar por fila cheia.

#### Scenario: Burst de comandos com fila de 4 cheia

- **WHEN** a fila interna de trabalho está cheia e chega novo comando MQTT
- **THEN** o firmware publica rejeição `fila_cheia` em vez de descartar silenciosamente
