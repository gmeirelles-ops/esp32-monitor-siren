## ADDED Requirements

### Requirement: Bloqueio de testes em falha de UART do PZEM-004T
O dispositivo SHALL travar novas execuções de teste caso perca a comunicação UART com o PZEM-004T.

#### Scenario: Perda de comunicação com o PZEM
- **WHEN** o dispositivo detecta falha de comunicação UART com o PZEM-004T
- **THEN** o dispositivo impede o início de novos testes até que a comunicação seja restabelecida

### Requirement: Alerta de falha de hardware via MQTT
O dispositivo SHALL publicar um alerta de falha de hardware via MQTT ao detectar perda de comunicação com o PZEM-004T.

#### Scenario: Publicação do alerta
- **WHEN** a falha de comunicação UART com o PZEM-004T é detectada
- **THEN** o dispositivo publica via MQTT uma mensagem de alerta de falha de hardware

### Requirement: Recuperação após restabelecimento do hardware
O dispositivo SHALL sair do estado `HARDWARE_FAULT` e voltar a permitir testes apenas após confirmar a recomunicação com o PZEM-004T.

#### Scenario: Comunicação restabelecida
- **WHEN** a comunicação UART com o PZEM-004T volta a responder de forma consistente
- **THEN** o dispositivo sai de `HARDWARE_FAULT`, retoma o estado anterior (`IDLE` ou `BATCH_READY`) e volta a aceitar acionamentos de teste

#### Scenario: Relé seguro durante a falha
- **WHEN** o dispositivo está em `HARDWARE_FAULT`
- **THEN** o relé permanece desligado e nenhum novo ciclo de teste é iniciado
