## ADDED Requirements

### Requirement: Modo Aprendizado para calibração de potência
O dispositivo SHALL executar um ciclo de calibração ao receber o comando `START_CALIBRATION`, medindo a potência média de uma peça padrão durante 5 segundos.

#### Scenario: Início da calibração
- **WHEN** o dispositivo recebe o comando `START_CALIBRATION` pela interface de cadastro de produtos
- **THEN** o dispositivo aciona o relé e executa um ciclo de teste de 5 segundos sobre a peça padrão

#### Scenario: Retorno da potência de referência
- **WHEN** o ciclo de calibração de 5 segundos é concluído
- **THEN** o dispositivo calcula a potência média exata e a publica via MQTT para preenchimento automatizado no banco de dados

### Requirement: Restrições de estado para calibração
O dispositivo SHALL aceitar `START_CALIBRATION` apenas quando não houver lote ativo nem teste em andamento, rejeitando o comando caso contrário.

#### Scenario: Calibração com lote ativo
- **WHEN** o dispositivo recebe `START_CALIBRATION` enquanto há um lote configurado (`BATCH_READY`) ou um teste em andamento (`TESTING`)
- **THEN** o dispositivo rejeita o comando e publica uma mensagem de rejeição, sem acionar o relé

#### Scenario: Calibração bloqueada por falha de hardware
- **WHEN** o dispositivo recebe `START_CALIBRATION` enquanto está em `HARDWARE_FAULT`
- **THEN** o dispositivo rejeita o comando e não executa o ciclo de calibração
