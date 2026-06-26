## ADDED Requirements

### Requirement: Autoteste PZEM no boot

O firmware SHALL tentar até 3 leituras PZEM logo após `pzem_init`. Se todas falharem, SHALL publicar alerta MQTT e entrar em `HARDWARE_FAULT`.

#### Scenario: PZEM conectado corretamente

- **WHEN** o dispositivo boota com UART funcional
- **THEN** pelo menos uma leitura no autoteste retorna sucesso e o estado permanece operacional

#### Scenario: UART desconectado no boot

- **WHEN** as 3 tentativas de boot falham
- **THEN** alerta `pzem_uart_boot` é publicado em `alerta` e testes ficam bloqueados até recuperação

#### Scenario: Recuperação após reconexão

- **WHEN** PZEM volta a responder após falha
- **THEN** `pzem_clear_fault` restaura operação (comportamento existente preservado)
