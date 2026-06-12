## ADDED Requirements

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
- **THEN** o resultado é gravado no banco local com timestamp, device_id, veredito e potencia_media
