## MODIFIED Requirements

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
