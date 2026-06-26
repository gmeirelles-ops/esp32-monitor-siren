## ADDED Requirements

### Requirement: Comando MQTT PZEM_PROBE para diagnóstico

O firmware SHALL aceitar `{ "cmd": "PZEM_PROBE" }` em `sirene/<device_id>/comando` e publicar resultado em `status` sem energizar o relé.

#### Scenario: Probe com UART OK

- **WHEN** `PZEM_PROBE` é recebido e a leitura Modbus succeeds
- **THEN** publica `{"tipo":"pzem","evento":"probe","potencia_w":<float>,"uart_ok":true}`

#### Scenario: Probe com UART falho

- **WHEN** `PZEM_PROBE` é recebido e a leitura falha
- **THEN** publica `{"tipo":"pzem","evento":"probe","potencia_w":0,"uart_ok":false}`

#### Scenario: Probe rejeitado durante teste

- **WHEN** estado é `TESTING` ou calibração ativa
- **THEN** rejeita com `cmd_durante_teste` (sem interferir no ciclo)
