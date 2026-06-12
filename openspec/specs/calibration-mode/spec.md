# calibration-mode Specification

## Purpose
Modo de calibração no firmware ESP32: ciclo `START_CALIBRATION` com amostras PZEM em tempo real e publicação do resultado de potência de referência.
## Requirements
### Requirement: Modo Aprendizado para calibração de potência
O dispositivo SHALL executar um ciclo de calibração ao receber o comando `START_CALIBRATION`, medindo a potência de uma peça padrão durante 5 segundos e publicando amostras periódicas em tempo real além da média final.

#### Scenario: Início da calibração
- **WHEN** o dispositivo recebe o comando `START_CALIBRATION` pela interface de cadastro de produtos
- **THEN** o dispositivo aciona o relé e executa um ciclo de teste de 5 segundos sobre a peça padrão

#### Scenario: Amostras em tempo real durante calibração
- **WHEN** o ciclo de calibração está em andamento após o período de descarte de inrush
- **THEN** o dispositivo publica em `sirene/<device_id>/calibracao` mensagens JSON com `tipo: "calibracao_amostra"`, contendo `potencia_w` e `elapsed_ms`, em intervalo de até 500 ms

#### Scenario: Retorno da potência de referência
- **WHEN** o ciclo de calibração de 5 segundos é concluído
- **THEN** o dispositivo calcula a potência média exata e a publica via MQTT com `tipo: "calibracao"` e campo `potencia_media` para preenchimento automatizado no cadastro de produtos

### Requirement: Restrições de estado para calibração
O dispositivo SHALL aceitar `START_CALIBRATION` apenas quando não houver lote ativo nem teste em andamento, rejeitando o comando caso contrário.

#### Scenario: Calibração com lote ativo
- **WHEN** o dispositivo recebe `START_CALIBRATION` enquanto há um lote configurado (`BATCH_READY`) ou um teste em andamento (`TESTING`)
- **THEN** o dispositivo rejeita o comando e publica uma mensagem de rejeição, sem acionar o relé

#### Scenario: Calibração bloqueada por falha de hardware
- **WHEN** o dispositivo recebe `START_CALIBRATION` enquanto está em `HARDWARE_FAULT`
- **THEN** o dispositivo rejeita o comando e não executa o ciclo de calibração

