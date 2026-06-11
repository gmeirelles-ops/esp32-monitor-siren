## MODIFIED Requirements

### Requirement: Task Watchdog nas tarefas críticas
O dispositivo SHALL monitorar as tarefas críticas com o Task Watchdog (TWDT), incluindo `worker`, `telemetry`, `offline_sync` e `hw_mon`, e SHALL reiniciar de forma controlada caso uma tarefa monitorada deixe de responder.

#### Scenario: Tarefa travada
- **WHEN** uma tarefa registrada no watchdog não alimenta o TWDT dentro do tempo limite
- **THEN** o dispositivo registra a falha e executa um reinício controlado

#### Scenario: Tarefa hw_mon alimenta watchdog
- **WHEN** a tarefa `hw_mon` está em execução normal monitorando recuperação do PZEM
- **THEN** ela alimenta o TWDT a cada iteração do loop sem disparar timeout
