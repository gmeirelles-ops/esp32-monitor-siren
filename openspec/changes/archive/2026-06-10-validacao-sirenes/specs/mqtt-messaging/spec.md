## ADDED Requirements

### Requirement: Broker MQTT configurado em tempo de compilação
O endereço do broker MQTT SHALL ser definido no firmware por meio de `#define` (hardcoded), não sendo configurável em tempo de execução.

#### Scenario: Conexão ao broker
- **WHEN** o dispositivo está em modo Station com rede disponível
- **THEN** o dispositivo conecta ao broker MQTT cujo endereço está definido via `#define` no firmware

### Requirement: Tópicos endereçados por dispositivo
O dispositivo SHALL usar tópicos MQTT que incluam um identificador único (`device_id`) derivado do seu endereço MAC, permitindo múltiplos dispositivos na mesma linha sem colisão.

#### Scenario: Estrutura dos tópicos
- **WHEN** o dispositivo conecta ao broker
- **THEN** ele assina o tópico de comando `sirene/<device_id>/comando` e publica em `sirene/<device_id>/status`, `sirene/<device_id>/calibracao` e `sirene/<device_id>/alerta`

### Requirement: Contrato do comando SET_BATCH
O dispositivo SHALL aceitar, no tópico `sirene/<device_id>/comando`, um payload JSON de configuração de lote com `cmd` igual a `SET_BATCH` contendo `numero_op`, `id_produto`, `ano`, `tempo_teste` (em segundos), `potencia_min`, `potencia_max`, `quantidade_total` e `proximo_sequencial`.

#### Scenario: Payload SET_BATCH válido
- **WHEN** chega no tópico de comando um JSON com `cmd: "SET_BATCH"` e todos os campos obrigatórios (`numero_op`, `id_produto`, `ano`, `tempo_teste`, `potencia_min`, `potencia_max`, `quantidade_total`, `proximo_sequencial`)
- **THEN** o dispositivo interpreta os campos e configura o lote com esses parâmetros

#### Scenario: Payload malformado ou incompleto
- **WHEN** chega um payload no tópico de comando que não contém todos os campos obrigatórios do `SET_BATCH`
- **THEN** o dispositivo descarta o comando, não altera a configuração de lote vigente e publica em `status` uma mensagem de rejeição

#### Scenario: SET_BATCH durante teste em andamento
- **WHEN** um `SET_BATCH` chega enquanto o dispositivo está executando um teste (`TESTING`)
- **THEN** o dispositivo rejeita o comando, mantém o lote corrente e publica uma mensagem de rejeição em `status`

### Requirement: Contrato do comando END_BATCH
O dispositivo SHALL aceitar um comando `END_BATCH` que encerra o lote ativo, limpando o contexto persistido.

#### Scenario: Encerramento de lote
- **WHEN** chega no tópico de comando um JSON com `cmd: "END_BATCH"` e nenhum teste está em andamento
- **THEN** o dispositivo encerra o lote, limpa o contexto persistido em NVS e retorna ao estado `IDLE`

#### Scenario: END_BATCH durante teste em andamento
- **WHEN** um `END_BATCH` chega enquanto um teste está em andamento (`TESTING`)
- **THEN** o dispositivo rejeita o comando e mantém o lote até a conclusão do teste corrente

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
