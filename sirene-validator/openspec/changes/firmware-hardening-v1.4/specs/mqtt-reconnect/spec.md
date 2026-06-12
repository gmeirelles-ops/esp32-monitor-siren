## MODIFIED Requirements

### Requirement: Reconexão MQTT usa guard contra tasks duplicadas

O firmware SHALL agendar no máximo uma tentativa de reconexão MQTT pendente por vez; desconexões adicionais durante backoff não criam tasks extras.

#### Scenario: Rede instável

- **WHEN** múltiplos eventos `MQTT_EVENT_DISCONNECTED` ocorrem em sequência rápida
- **THEN** apenas uma task de reconnect está ativa e o backoff exponencial continua válido
