## ADDED Requirements

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
