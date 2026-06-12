## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Rejeição imediata de comandos durante calibração
O dispositivo SHALL rejeitar imediatamente, sem enfileiramento, os comandos `SET_BATCH`, `END_BATCH`, `START_CALIBRATION` e `OTA_UPDATE` recebidos enquanto um ciclo de calibração (`START_CALIBRATION`) estiver em andamento.

#### Scenario: END_BATCH durante calibração
- **WHEN** um `END_BATCH` chega enquanto o dispositivo executa calibração
- **THEN** o dispositivo rejeita o comando, não altera o lote e publica rejeição em `status`

#### Scenario: OTA_UPDATE durante teste
- **WHEN** um `OTA_UPDATE` chega enquanto o dispositivo está em estado `TESTING`
- **THEN** o dispositivo rejeita o comando imediatamente sem enfileirá-lo e publica rejeição em `status`
