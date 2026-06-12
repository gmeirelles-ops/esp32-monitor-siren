## ADDED Requirements

### Requirement: Formulário de configuração de lote
O app SHALL oferecer formulário para enviar `SET_BATCH` com todos os campos obrigatórios: numero_op, id_produto, ano, tempo_teste, potencia_min, potencia_max, quantidade_total e proximo_sequencial.

#### Scenario: Lote configurado com sucesso
- **WHEN** o operador preenche todos os campos e confirma
- **THEN** o app envia `SET_BATCH` via MQTT e aguarda heartbeat com `estado: "BATCH_READY"` em até 10 segundos

#### Scenario: Timeout na confirmação
- **WHEN** o heartbeat com `BATCH_READY` não chega em 10 segundos após `SET_BATCH`
- **THEN** o app exibe erro de timeout e oferece opção de retry

### Requirement: Encerramento de lote
O app SHALL permitir enviar `END_BATCH` para encerrar o lote ativo de um dispositivo.

#### Scenario: Lote encerrado
- **WHEN** o operador aciona "Encerrar lote" e o dispositivo não está em `TESTING`
- **THEN** o app envia `END_BATCH` e aguarda heartbeat com `estado: "IDLE"`

### Requirement: Indicação de teste via botão físico
O app SHALL exibir instrução para pressionar o botão físico do dispositivo quando o estado for `BATCH_READY`.

#### Scenario: Aguardando teste
- **WHEN** o heartbeat indica `estado: "BATCH_READY"`
- **THEN** o app exibe mensagem "Pressione o botão no dispositivo para iniciar o teste"

#### Scenario: Teste em andamento
- **WHEN** o heartbeat indica `estado: "TESTING"`
- **THEN** o app exibe indicador visual de teste em andamento (spinner/animacao amber)

### Requirement: Acompanhamento de progresso do lote
O app SHALL exibir `aprovados_no_lote` e `quantidade_total` e alertar quando a meta for atingida.

#### Scenario: Meta de quantidade atingida
- **WHEN** `aprovados_no_lote` atinge ou supera `quantidade_total` configurado
- **THEN** o app exibe alerta sugerindo encerramento do lote

### Requirement: Exibição de resultados em tempo real
O app SHALL exibir cada resultado de teste (aprovado/reprovado) com potência média e sequencial assim que recebido via MQTT.

#### Scenario: Sirene aprovada
- **WHEN** chega resultado com `veredito: "APROVADO"`
- **THEN** o app exibe card verde com potencia_media, sequencial e aprovados_no_lote

#### Scenario: Sirene reprovada
- **WHEN** chega resultado com `veredito: "REPROVADO"`
- **THEN** o app exibe card vermelho com potencia_media e indica que o sequencial não foi consumido
