## ADDED Requirements

### Requirement: Task Watchdog nas tarefas críticas
O dispositivo SHALL monitorar as tarefas críticas com o Task Watchdog (TWDT) e SHALL reiniciar de forma controlada caso uma tarefa monitorada deixe de responder.

#### Scenario: Tarefa travada
- **WHEN** uma tarefa registrada no watchdog não alimenta o TWDT dentro do tempo limite
- **THEN** o dispositivo registra a falha e executa um reinício controlado

### Requirement: Reconexão automática com backoff
O dispositivo SHALL reconectar automaticamente ao Wi-Fi e ao broker MQTT após uma queda, usando backoff exponencial limitado, sem interromper a execução de testes.

#### Scenario: Queda de Wi-Fi
- **WHEN** a conexão Wi-Fi cai durante a operação
- **THEN** o dispositivo tenta reconectar periodicamente com intervalos crescentes até um teto, mantendo o fluxo de teste ativo

#### Scenario: Queda do broker MQTT
- **WHEN** a conexão com o broker MQTT cai
- **THEN** o dispositivo tenta reestabelecer a sessão com backoff e retoma as publicações pendentes ao reconectar

### Requirement: Recuperação preserva estado seguro
O dispositivo SHALL manter o relé desligado e o lote persistido durante qualquer reinício de recuperação.

#### Scenario: Reinício por watchdog durante lote
- **WHEN** ocorre um reinício controlado por watchdog com um lote ativo
- **THEN** após o boot o relé permanece desligado e o lote é restaurado a partir da NVS
