# device-monitoring Specification

## Purpose
Monitoramento operacional de dispositivos ESP32 na linha de produção: presença, saúde, alertas de hardware e detecção de dispositivos stale.
## Requirements
### Requirement: Lista de dispositivos descobertos
O app SHALL manter uma lista de dispositivos descobertos automaticamente via mensagens `presenca` e `heartbeat`.

#### Scenario: Novo dispositivo detectado
- **WHEN** o app recebe a primeira mensagem de `sirene/<device_id>/heartbeat`
- **THEN** o dispositivo é adicionado à lista com seu device_id e timestamp da última atividade

#### Scenario: Dispositivo offline
- **WHEN** o app recebe `offline` em `sirene/<device_id>/presenca` (LWT)
- **THEN** o dispositivo é marcado como offline na lista

### Requirement: Dashboard de saúde do dispositivo
O app SHALL exibir para cada dispositivo: estado FSM, RSSI, uptime, profundidade da fila offline, versão de firmware e status de presença.

#### Scenario: Detalhe do dispositivo
- **WHEN** o operador seleciona um dispositivo na lista
- **THEN** o app exibe o estado atual (IDLE, BATCH_READY, TESTING, etc.), RSSI, uptime, fila offline e firmware_version do último heartbeat

### Requirement: Alertas de hardware
O app SHALL exibir alertas quando receber mensagens em `sirene/<device_id>/alerta`.

#### Scenario: Falha PZEM detectada
- **WHEN** chega `{"tipo": "hardware", "falha": "pzem_uart"}`
- **THEN** o app exibe alerta visual destacado (cor de erro) indicando falha de hardware no dispositivo

### Requirement: Histórico local de testes
O app SHALL persistir localmente cada resultado de teste recebido via MQTT.

#### Scenario: Teste salvo localmente
- **WHEN** o app recebe um resultado de teste (`tipo: "teste"`)
- **THEN** o resultado é gravado no banco local com timestamp, device_id, veredito, potencia_media e operador (quando autenticado)

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

### Requirement: Espelhamento de estado do dispositivo na nuvem
Quando a sincronização Firestore estiver habilitada e o operador autenticado, o app SHALL enfileirar atualização da coleção `devices/{device_id}` a cada mudança relevante de presença ou heartbeat processada localmente.

#### Scenario: Heartbeat atualiza dispositivo na nuvem
- **WHEN** o app processa heartbeat de um dispositivo com sync habilitado
- **THEN** o sync service recebe `device_id`, `estado`, `firmware_version`, `rssi`, `fila_offline`, `online: true` e `last_seen` para enfileiramento

#### Scenario: LWT offline atualiza dispositivo na nuvem
- **WHEN** o app recebe `presenca: offline` para um dispositivo com sync habilitado
- **THEN** o sync service enfileira atualização imediata com `online: false` para o mesmo `device_id`

### Requirement: Histórico local permanece primário
A persistência local de resultados de teste SHALL permanecer obrigatória e independente do estado da sincronização em nuvem.

#### Scenario: Sync desabilitado ou falha de rede
- **WHEN** o app recebe resultado de teste via MQTT com sync desabilitado ou Firestore indisponível
- **THEN** o resultado é gravado no SQLite local normalmente, sem bloquear o fluxo de etiquetas

