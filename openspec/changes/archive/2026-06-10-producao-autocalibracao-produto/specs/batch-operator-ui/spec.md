## MODIFIED Requirements

### Requirement: Formulário de configuração de lote
O app SHALL oferecer formulário para enviar `SET_BATCH` selecionando um produto cadastrado, preenchendo automaticamente `id_produto`, `tempo_teste`, `potencia_min` e `potencia_max`, e solicitando ao operador apenas `numero_op`, `ano`, `quantidade_total` e `proximo_sequencial`.

#### Scenario: Lote configurado a partir de produto cadastrado
- **WHEN** o operador seleciona um produto cadastrado, preenche OP/ano/quantidade/sequencial e confirma
- **THEN** o app monta o payload `SET_BATCH` com os limites do produto e envia via MQTT, aguardando heartbeat com `estado: "BATCH_READY"` em até 10 segundos

#### Scenario: Timeout na confirmação
- **WHEN** o heartbeat com `BATCH_READY` não chega em 10 segundos após `SET_BATCH`
- **THEN** o app exibe erro de timeout e oferece opção de retry

#### Scenario: Nenhum produto cadastrado
- **WHEN** o operador abre a tela de lote e não há produtos no catálogo
- **THEN** o app exibe mensagem orientando cadastrar um produto na seção Produtos antes de configurar o lote

## ADDED Requirements

### Requirement: Exibição dos limites do produto no lote
O app SHALL exibir `potencia_min`, `potencia_max` e `tempo_teste` do produto selecionado como campos somente leitura no formulário de lote.

#### Scenario: Limites visíveis ao selecionar produto
- **WHEN** o operador seleciona um produto no dropdown do lote
- **THEN** o app preenche e exibe os limites e tempo de teste cadastrados, sem permitir edição direta na tela de lote
