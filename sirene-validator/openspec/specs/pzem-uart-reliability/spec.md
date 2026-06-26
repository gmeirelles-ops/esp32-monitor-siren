## ADDED Requirements

### Requirement: Driver PZEM aguarda resposta Modbus antes de ler UART

O firmware SHALL aguardar conclusão da transmissão UART e um delay configurável (`PZEM_RESPONSE_DELAY_MS`) antes de ler a resposta Modbus do PZEM-004T.

#### Scenario: Leitura bem-sucedida após delay

- **WHEN** o PZEM responde dentro de `PZEM_READ_TIMEOUT_MS` após o delay pós-TX
- **THEN** `pzem_read_power_w` retorna `true` e preenche potência em watts (raw × 0.1)

#### Scenario: Timeout UART

- **WHEN** nenhum byte válido chega dentro do timeout
- **THEN** `pzem_read_power_w` retorna `false` e o log registra motivo `timeout` com hex dump parcial se houver bytes

### Requirement: Validação completa da trama Modbus

O firmware SHALL validar endereço escravo, função `0x04`, byte-count `0x02` e CRC Modbus RTU antes de interpretar o registrador de potência.

#### Scenario: CRC inválido

- **WHEN** a resposta tem CRC incorreto
- **THEN** a leitura é descartada e contabilizada como erro consecutivo

## MODIFIED Requirements

### Requirement: Constantes de timing em board_config

`board_config.h` SHALL expor `PZEM_RESPONSE_DELAY_MS` e `PZEM_READ_TIMEOUT_MS` além de `PZEM_SAMPLE_READ_RETRIES`.

#### Scenario: Build reproduzível

- **WHEN** o operador altera timeout para bancada lenta
- **THEN** basta editar `board_config.h` e recompilar, sem mudar `pzem.c`
