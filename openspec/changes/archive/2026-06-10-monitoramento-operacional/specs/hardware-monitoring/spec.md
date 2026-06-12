## ADDED Requirements

### Requirement: Alerta de recuperação de hardware via MQTT
O dispositivo SHALL publicar um alerta de recuperação via MQTT ao sair do estado `HARDWARE_FAULT` após recomunicação com o PZEM-004T.

#### Scenario: Publicação de recuperação
- **WHEN** a comunicação UART com o PZEM-004T é restabelecida e o dispositivo sai de `HARDWARE_FAULT`
- **THEN** o dispositivo publica em `alerta` um JSON com `tipo: "hardware"` e `evento: "recuperado"`
