## ADDED Requirements

### Requirement: Conexão ao broker MQTT
O app SHALL conectar-se ao broker MQTT configurado usando protocolo TCP plain (`mqtt://`), compatível com o firmware.

#### Scenario: Conexão bem-sucedida
- **WHEN** o broker está acessível na rede e o app inicia ou retoma
- **THEN** o app estabelece conexão MQTT e exibe status "Conectado"

#### Scenario: Reconexão automática
- **WHEN** a conexão MQTT é perdida
- **THEN** o app tenta reconectar com backoff exponencial (1s a 30s) sem intervenção do operador

### Requirement: Subscribe nos tópicos do dispositivo
O app SHALL assinar os tópicos `sirene/+/presenca`, `sirene/+/heartbeat`, `sirene/+/status`, `sirene/+/calibracao` e `sirene/+/alerta` usando wildcard para descoberta multi-dispositivo.

#### Scenario: Recebimento de heartbeat
- **WHEN** um dispositivo publica em `sirene/<device_id>/heartbeat`
- **THEN** o app parseia o JSON e disponibiliza uptime, rssi, estado, fila e firmware_version

#### Scenario: Recebimento de presença
- **WHEN** um dispositivo publica `online` ou `offline` em `sirene/<device_id>/presenca`
- **THEN** o app atualiza o status de presença do dispositivo correspondente

### Requirement: Publicação de comandos
O app SHALL publicar comandos JSON no tópico `sirene/<device_id>/comando` com QoS 1.

#### Scenario: Envio de SET_BATCH
- **WHEN** o operador confirma a configuração de um lote
- **THEN** o app publica o payload `SET_BATCH` completo no tópico `sirene/<device_id>/comando`

### Requirement: Parsing de mensagens de status
O app SHALL parsear mensagens JSON de `status` distinguindo `tipo: "teste"`, `tipo: "rejeicao"` e `tipo: "ota"`.

#### Scenario: Resultado de teste parseado
- **WHEN** chega uma mensagem com `tipo: "teste"`
- **THEN** o app extrai numero_op, veredito, potencia_media, sequencial e aprovados_no_lote

#### Scenario: Rejeição de comando parseada
- **WHEN** chega uma mensagem com `tipo: "rejeicao"`
- **THEN** o app extrai o campo motivo e exibe feedback ao operador
