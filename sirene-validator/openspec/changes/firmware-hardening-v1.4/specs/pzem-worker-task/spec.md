## ADDED Requirements

### Requirement: Medição PZEM executa em task dedicada

O firmware SHALL executar `run_test_cycle` e `handle_start_calibration` em task FreeRTOS separada da `worker_task`, evitando bloqueio prolongado do processamento de comandos MQTT.

#### Scenario: Teste em andamento

- **WHEN** um ciclo de teste de 5 segundos está ativo na task PZEM
- **THEN** a `worker_task` continua capaz de receber e enfileirar comandos MQTT (sujeito à fila)

#### Scenario: Botão durante teste

- **WHEN** o operador pressiona o botão com teste já em andamento
- **THEN** o segundo teste é ignorado (comportamento atual preservado via `button_set_test_in_progress`)

### Requirement: Apenas um ciclo PZEM por vez

O firmware SHALL rejeitar ou ignorar novo disparo de teste/calibração enquanto a task PZEM estiver ocupada.

#### Scenario: SET_BATCH durante teste

- **WHEN** teste está em `TESTING`
- **THEN** `SET_BATCH` continua sendo rejeitado com `cmd_durante_teste` (sem regressão)
