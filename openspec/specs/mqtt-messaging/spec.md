# mqtt-messaging Specification

## Purpose
Contratos MQTT do firmware ESP32: broker, tópicos, comandos, status, calibração, alertas e telemetria.
## Requirements
### Requirement: Broker MQTT configurável via NVS
O endereço do broker MQTT SHALL ser resolvido em tempo de execução a partir da NVS (`mqtt_cfg`), utilizando o valor definido via `#define` em `board_config.h` apenas como fallback quando não houver configuração persistida.

#### Scenario: Conexão com broker da NVS
- **WHEN** o dispositivo está em modo Station, possui `mqtt_cfg` válido na NVS e a rede está disponível
- **THEN** o dispositivo conecta ao broker MQTT cujo host e porta foram lidos da NVS

#### Scenario: Conexão com fallback de compilação
- **WHEN** o dispositivo está em modo Station, não possui `mqtt_cfg` na NVS e a rede está disponível
- **THEN** o dispositivo conecta ao broker definido por `MQTT_BROKER_URI` em `board_config.h`

#### Scenario: URI montada corretamente
- **WHEN** a NVS contém host `192.168.51.87` e porta `1883`
- **THEN** o cliente MQTT utiliza a URI `mqtt://192.168.51.87:1883`

### Requirement: Tópicos endereçados por dispositivo
O dispositivo SHALL usar tópicos MQTT que incluam um identificador único (`device_id`) derivado do seu endereço MAC, permitindo múltiplos dispositivos na mesma linha sem colisão.

#### Scenario: Estrutura dos tópicos
- **WHEN** o dispositivo conecta ao broker
- **THEN** ele assina o tópico de comando `sirene/<device_id>/comando` e publica em `sirene/<device_id>/status`, `sirene/<device_id>/calibracao` e `sirene/<device_id>/alerta`

### Requirement: Contrato do comando SET_BATCH
O dispositivo SHALL aceitar, no tópico `sirene/<device_id>/comando`, um payload JSON de configuração de lote com `cmd` igual a `SET_BATCH` contendo `numero_op`, `id_produto`, `ano`, `tempo_teste` (em segundos), `potencia_min`, `potencia_max`, `quantidade_total` e `proximo_sequencial`. Comandos recebidos durante teste ou calibração SHALL ser rejeitados imediatamente, sem enfileiramento para processamento posterior.

#### Scenario: Payload SET_BATCH válido
- **WHEN** chega no tópico de comando um JSON com `cmd: "SET_BATCH"` e todos os campos obrigatórios (`numero_op`, `id_produto`, `ano`, `tempo_teste`, `potencia_min`, `potencia_max`, `quantidade_total`, `proximo_sequencial`)
- **THEN** o dispositivo interpreta os campos e configura o lote com esses parâmetros

#### Scenario: Payload malformado ou incompleto
- **WHEN** chega um payload no tópico de comando que não contém todos os campos obrigatórios do `SET_BATCH`
- **THEN** o dispositivo descarta o comando, não altera a configuração de lote vigente e publica em `status` uma mensagem de rejeição

#### Scenario: SET_BATCH durante teste em andamento
- **WHEN** um `SET_BATCH` chega enquanto o dispositivo está executando um teste (`TESTING`)
- **THEN** o dispositivo rejeita o comando imediatamente, mantém o lote corrente, não enfileira o comando para execução tardia e publica uma mensagem de rejeição em `status`

### Requirement: Contrato do comando END_BATCH
O dispositivo SHALL aceitar um comando `END_BATCH` que encerra o lote ativo, limpando o contexto persistido. Comandos recebidos durante teste ou calibração SHALL ser rejeitados imediatamente, sem enfileiramento para execução posterior.

#### Scenario: Encerramento de lote
- **WHEN** chega no tópico de comando um JSON com `cmd: "END_BATCH"` e nenhum teste está em andamento
- **THEN** o dispositivo encerra o lote, limpa o contexto persistido em NVS e retorna ao estado `IDLE`

#### Scenario: END_BATCH durante teste em andamento
- **WHEN** um `END_BATCH` chega enquanto um teste está em andamento (`TESTING`)
- **THEN** o dispositivo rejeita o comando imediatamente, mantém o lote até a conclusão do teste corrente, não enfileira o comando e publica rejeição em `status`

### Requirement: Publicação de status de teste
O dispositivo SHALL publicar em `sirene/<device_id>/status` o resultado de cada teste, incluindo `numero_op`, veredito (`APROVADO`/`REPROVADO`), `potencia_media`, `sequencial` e `aprovados_no_lote`.

#### Scenario: Resultado de teste publicado
- **WHEN** um teste é concluído com conexão disponível
- **THEN** o dispositivo publica em `status` uma mensagem JSON contendo o veredito, a potência média, o sequencial e a OP associados

### Requirement: Publicação do resultado de calibração
O dispositivo SHALL publicar em `sirene/<device_id>/calibracao` a potência média de referência ao concluir um ciclo de calibração.

#### Scenario: Resultado de calibração publicado
- **WHEN** um ciclo `START_CALIBRATION` é concluído
- **THEN** o dispositivo publica em `calibracao` a potência média medida para preenchimento no cadastro de produtos

### Requirement: Publicação de alerta de hardware
O dispositivo SHALL publicar em `sirene/<device_id>/alerta` uma mensagem de falha sempre que detectar perda de comunicação com hardware crítico.

#### Scenario: Alerta de falha de hardware
- **WHEN** o dispositivo detecta perda de comunicação UART com o PZEM-004T
- **THEN** o dispositivo publica em `alerta` uma mensagem JSON identificando a falha de hardware

### Requirement: Contrato do comando OTA_UPDATE
O dispositivo SHALL aceitar, no tópico `sirene/<device_id>/comando`, um payload JSON com `cmd` igual a `OTA_UPDATE` contendo a `url` da imagem de firmware.

#### Scenario: Payload OTA_UPDATE válido
- **WHEN** chega um JSON com `cmd: "OTA_UPDATE"` e `url` não vazia
- **THEN** o dispositivo aceita o comando e inicia o processo de atualização OTA

#### Scenario: OTA_UPDATE sem url
- **WHEN** chega um payload `OTA_UPDATE` sem o campo `url` ou com `url` vazia
- **THEN** o dispositivo descarta o comando e publica uma mensagem de rejeição

### Requirement: Tópicos de telemetria do dispositivo
O dispositivo SHALL publicar presença e heartbeat em tópicos dedicados endereçados por dispositivo.

#### Scenario: Tópicos de telemetria
- **WHEN** o dispositivo está conectado ao broker
- **THEN** ele utiliza `sirene/<device_id>/presenca` para presença (online/offline via LWT) e `sirene/<device_id>/heartbeat` para o heartbeat periódico

### Requirement: Publicação de amostras de calibração em tempo real
O dispositivo SHALL publicar amostras periódicas de potência no tópico `sirene/<device_id>/calibracao` durante o ciclo de `START_CALIBRATION`, além da mensagem final com a média.

#### Scenario: Amostra publicada durante calibração
- **WHEN** o ciclo de calibração está em andamento após o descarte de inrush
- **THEN** o dispositivo publica JSON com `tipo: "calibracao_amostra"`, `potencia_w` (float) e `elapsed_ms` (inteiro) em intervalo máximo de 500 ms

#### Scenario: Mensagem final após amostras
- **WHEN** o ciclo de calibração de 5 segundos é concluído com sucesso
- **THEN** o dispositivo publica JSON com `tipo: "calibracao"` e `potencia_media` como última mensagem do ciclo

### Requirement: Rejeição imediata de comandos durante calibração
O dispositivo SHALL rejeitar imediatamente, sem enfileiramento, os comandos `SET_BATCH`, `END_BATCH`, `START_CALIBRATION` e `OTA_UPDATE` recebidos enquanto um ciclo de calibração (`START_CALIBRATION`) estiver em andamento.

#### Scenario: END_BATCH durante calibração
- **WHEN** um `END_BATCH` chega enquanto o dispositivo executa calibração
- **THEN** o dispositivo rejeita o comando, não altera o lote e publica rejeição em `status`

#### Scenario: OTA_UPDATE durante teste
- **WHEN** um `OTA_UPDATE` chega enquanto o dispositivo está em estado `TESTING`
- **THEN** o dispositivo rejeita o comando imediatamente sem enfileirá-lo e publica rejeição em `status`

