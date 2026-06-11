## MODIFIED Requirements

### Requirement: Sincronização em segundo plano após reconexão
O dispositivo SHALL realizar, por meio de um módulo em segundo plano, o dump de todas as mensagens acumuladas assim que a conexão de rede retornar, republicando cada mensagem no **mesmo sufixo de tópico MQTT** (`status`, `alerta` ou `calibracao`) usado no momento em que foi enfileirada.

#### Scenario: Reconexão de rede
- **WHEN** a conexão Wi-Fi e com o broker MQTT é restabelecida
- **THEN** o módulo de sincronização envia as mensagens persistidas em ordem FIFO, cada uma no tópico de origem correto, e as remove da fila local após confirmação de publicação

#### Scenario: Mensagem de alerta enfileirada offline
- **WHEN** um alerta de hardware é gerado sem conexão MQTT e posteriormente a rede retorna
- **THEN** o alerta é publicado em `sirene/<device_id>/alerta`, não em `status`

#### Scenario: Resultado de calibração enfileirado offline
- **WHEN** um ciclo de calibração conclui sem conexão MQTT e a rede retorna
- **THEN** o JSON de calibração é publicado em `sirene/<device_id>/calibracao`

#### Scenario: Entrada legada sem metadado de tópico
- **WHEN** a fila contém uma entrada persistida antes da atualização (somente corpo JSON, sem sufixo de tópico)
- **THEN** o dispositivo trata essa entrada como pertencente ao tópico `status` ao drenar
