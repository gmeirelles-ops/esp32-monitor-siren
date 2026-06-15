## MODIFIED Requirements

### Requirement: Contrato do comando SET_BATCH
O dispositivo SHALL aceitar, no tópico `sirene/<device_id>/comando`, um payload JSON de configuração de lote com `cmd` igual a `SET_BATCH` contendo `numero_op`, `id_produto`, `ano`, `tempo_teste` (em segundos), `potencia_min`, `potencia_max`, `quantidade_total`, `proximo_sequencial` e campo opcional `modo_reteste` (boolean, padrão `false`). Comandos recebidos durante teste ou calibração SHALL ser rejeitados imediatamente, sem enfileiramento para processamento posterior.

#### Scenario: Payload SET_BATCH válido
- **WHEN** chega no tópico de comando um JSON com `cmd: "SET_BATCH"` e todos os campos obrigatórios (`numero_op`, `id_produto`, `ano`, `tempo_teste`, `potencia_min`, `potencia_max`, `quantidade_total`, `proximo_sequencial`)
- **THEN** o dispositivo interpreta os campos, aplica `modo_reteste` quando presente e configura o lote com esses parâmetros

#### Scenario: Payload malformado ou incompleto
- **WHEN** chega um payload no tópico de comando que não contém todos os campos obrigatórios do `SET_BATCH`
- **THEN** o dispositivo descarta o comando, não altera a configuração de lote vigente e publica em `status` uma mensagem de rejeição

#### Scenario: SET_BATCH durante teste em andamento
- **WHEN** um `SET_BATCH` chega enquanto o dispositivo está executando um teste (`TESTING`)
- **THEN** o dispositivo rejeita o comando imediatamente, mantém o lote corrente, não enfileira o comando para execução tardia e publica uma mensagem de rejeição em `status`

#### Scenario: Alternância de modo reteste
- **WHEN** chega `SET_BATCH` com os mesmos parâmetros de lote e `modo_reteste` alterado sem teste em andamento
- **THEN** o dispositivo atualiza apenas `modo_reteste` e mantém contadores e sequencial correntes
