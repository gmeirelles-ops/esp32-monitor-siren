# batch-operator-ui Specification

## Purpose
Interface de operação de lote no app Flutter: configuração `SET_BATCH`, acompanhamento do último teste e encerramento `END_BATCH` por dispositivo.
## Requirements
### Requirement: Formulário de configuração de lote
O app SHALL oferecer formulário para enviar `SET_BATCH` selecionando um produto cadastrado, preenchendo automaticamente `id_produto`, `tempo_teste`, `potencia_min` e `potencia_max`, sugerindo automaticamente `proximo_sequencial` a partir do contador por `(id_produto, ano)`, e solicitando ao operador `numero_op`, `ano` e `quantidade_total`.

#### Scenario: Lote configurado a partir de produto cadastrado
- **WHEN** o operador seleciona um produto cadastrado, preenche OP/ano/quantidade e confirma
- **THEN** o app monta o payload `SET_BATCH` com os limites do produto e o `proximo_sequencial` sugerido, e envia via MQTT, aguardando heartbeat com `estado: "BATCH_READY"` em até 10 segundos

#### Scenario: Sequencial pré-preenchido ao escolher produto/ano
- **WHEN** o operador seleciona um produto ou altera o ano no formulário de lote
- **THEN** o app pré-preenche `proximo_sequencial` com o último sequencial conhecido de `(id_produto, ano)` mais um, mantendo o campo editável

#### Scenario: Timeout na confirmação
- **WHEN** o heartbeat com `BATCH_READY` não chega em 10 segundos após `SET_BATCH`
- **THEN** o app exibe erro de timeout e oferece opção de retry

#### Scenario: Nenhum produto cadastrado
- **WHEN** o operador abre a tela de lote e não há produtos no catálogo
- **THEN** o app exibe mensagem orientando cadastrar um produto na seção Produtos antes de configurar o lote

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

### Requirement: Exibição dos limites do produto no lote
O app SHALL exibir `potencia_min`, `potencia_max` e `tempo_teste` do produto selecionado como campos somente leitura no formulário de lote.

#### Scenario: Limites visíveis ao selecionar produto
- **WHEN** o operador seleciona um produto no dropdown do lote
- **THEN** o app preenche e exibe os limites e tempo de teste cadastrados, sem permitir edição direta na tela de lote

