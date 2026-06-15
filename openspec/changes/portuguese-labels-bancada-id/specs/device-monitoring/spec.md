## MODIFIED Requirements

### Requirement: Lista de dispositivos descobertos
O app SHALL manter uma lista de bancadas descobertas automaticamente via mensagens `presenca` e `heartbeat`, exibindo número sequencial de bancada (`Bancada N`) como identificação principal.

#### Scenario: Nova bancada detectada
- **WHEN** o app recebe a primeira mensagem de `sirene/<device_id>/heartbeat`
- **THEN** a bancada é adicionada à lista com número sequencial atribuído e timestamp da última atividade

#### Scenario: Bancada desconectada
- **WHEN** o app recebe `offline` em `sirene/<device_id>/presenca` (LWT)
- **THEN** a bancada é marcada como desconectada na lista, mantendo o mesmo número

### Requirement: Dashboard de saúde do dispositivo
O app SHALL exibir para cada bancada: estado FSM, RSSI, uptime, profundidade da fila offline, versão de firmware e status de presença, com título `Bancada N` e identificador técnico (MAC) em campo secundário.

#### Scenario: Detalhe da bancada
- **WHEN** o operador seleciona uma bancada na lista
- **THEN** o app exibe o estado atual, métricas de saúde e identificador técnico MQTT sem usar o MAC como título principal
