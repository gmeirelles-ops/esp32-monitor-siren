## MODIFIED Requirements

### Requirement: Histórico local de testes
O app SHALL persistir localmente cada resultado de teste recebido via MQTT.

#### Scenario: Teste salvo localmente
- **WHEN** o app recebe um resultado de teste (`tipo: "teste"`)
- **THEN** o resultado é gravado no banco local com timestamp, device_id, veredito, potencia_media e operador (quando autenticado)
