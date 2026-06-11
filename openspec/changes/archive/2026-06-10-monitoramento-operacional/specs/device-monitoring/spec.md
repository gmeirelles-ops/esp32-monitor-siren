## ADDED Requirements

### Requirement: Detecção de dispositivo stale por ausência de heartbeat
O app SHALL marcar um dispositivo como offline quando não receber mensagem de `heartbeat` ou `presenca` por um intervalo configurável, mesmo que o LWT não tenha sido disparado.

#### Scenario: Heartbeat ausente
- **WHEN** um dispositivo está marcado online e não envia `heartbeat` nem atualiza `presenca` por mais de 90 segundos
- **THEN** o app marca o dispositivo como offline na lista e no detalhe

#### Scenario: Heartbeat retoma
- **WHEN** um dispositivo stale publica novo `heartbeat`
- **THEN** o app marca o dispositivo como online e atualiza `lastSeen`

### Requirement: Limpeza de alerta de hardware recuperado
O app SHALL remover o alerta de hardware exibido quando o dispositivo recuperar operação normal.

#### Scenario: FSM sai de HARDWARE_FAULT
- **WHEN** o app recebe heartbeat com `estado` diferente de `HARDWARE_FAULT` para um dispositivo que tinha alerta ativo
- **THEN** o app remove o alerta visual de falha de hardware desse dispositivo

#### Scenario: Mensagem de recuperação recebida
- **WHEN** chega em `alerta` um JSON com `tipo: "hardware"` e `evento: "recuperado"`
- **THEN** o app remove o alerta de falha de hardware do dispositivo correspondente
