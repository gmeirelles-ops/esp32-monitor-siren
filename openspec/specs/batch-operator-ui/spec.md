# batch-operator-ui Specification

## Purpose
Interface de operação de lote no app Flutter: configuração `SET_BATCH`, acompanhamento do último teste e encerramento `END_BATCH` por dispositivo.
## Requirements
### Requirement: Formulário de configuração de lote
O app SHALL oferecer formulário para enviar `SET_BATCH` selecionando um produto cadastrado, preenchendo automaticamente `id_produto`, `tempo_teste`, `potencia_min` e `potencia_max`, sugerindo automaticamente `proximo_sequencial` a partir do contador por `(id_produto, ano)`, e solicitando ao operador `numero_op`, `ano` e `quantidade_total`. O acompanhamento detalhado do lote em execução SHALL ocorrer na tela Batch Live Dashboard, não neste formulário.

#### Scenario: Lote configurado a partir de produto cadastrado
- **WHEN** o operador seleciona um produto cadastrado, preenche OP/ano/quantidade e confirma
- **THEN** o app monta o payload `SET_BATCH` com os limites do produto e o `proximo_sequencial` sugerido, envia via MQTT, aguarda rejeição por até 3 segundos e, se aceito, navega para o Batch Live Dashboard

#### Scenario: Sequencial pré-preenchido ao escolher produto/ano
- **WHEN** o operador seleciona um produto ou altera o ano no formulário de lote
- **THEN** o app pré-preenche `proximo_sequencial` com o último sequencial conhecido de `(id_produto, ano)` mais um, mantendo o campo editável

#### Scenario: Comando rejeitado
- **WHEN** o firmware publica rejeição em até 3 segundos após `SET_BATCH`
- **THEN** o app exibe o motivo da rejeição e permanece na tela de configuração

#### Scenario: Nenhum produto cadastrado
- **WHEN** o operador abre a tela de lote e não há produtos no catálogo
- **THEN** o app exibe mensagem orientando cadastrar um produto na seção Produtos antes de configurar o lote

### Requirement: Encerramento de lote
O app SHALL permitir enviar `END_BATCH` a partir do Batch Live Dashboard (e opcionalmente da tela de configuração quando aplicável).

#### Scenario: Lote encerrado
- **WHEN** o operador aciona "Encerrar lote" e o dispositivo não está em `TESTING`
- **THEN** o app envia `END_BATCH`, aguarda rejeição por até 3 segundos e, se aceito, atualiza estado local para IDLE

### Requirement: Exibição dos limites do produto no lote
O app SHALL exibir `potencia_min`, `potencia_max` e `tempo_teste` do produto selecionado como campos somente leitura no formulário de lote.

#### Scenario: Limites visíveis ao selecionar produto
- **WHEN** o operador seleciona um produto no dropdown do lote
- **THEN** o app preenche e exibe os limites e tempo de teste cadastrados, sem permitir edição direta na tela de lote

