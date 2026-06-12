## MODIFIED Requirements

### Requirement: Formulário de configuração de lote
O app SHALL oferecer formulário para enviar `SET_BATCH` na tela inicial **Lote**, com seção explícita de operador ativo, seleção de dispositivo com indicação de presença online, produto cadastrado e campos de OP/ano/quantidade. O envio SHALL ser bloqueado sem operador ativo selecionado.

#### Scenario: Lote configurado a partir de produto cadastrado
- **WHEN** o operador ativo está selecionado, escolhe dispositivo e produto, preenche OP/ano/quantidade e confirma
- **THEN** o app monta o payload `SET_BATCH`, envia via MQTT, aguarda rejeição por até 3 segundos e, se aceito, navega para o Batch Live Dashboard

#### Scenario: Sequencial pré-preenchido ao escolher produto/ano
- **WHEN** o operador seleciona um produto ou altera o ano no formulário de lote
- **THEN** o app pré-preenche `proximo_sequencial` com o último sequencial conhecido de `(id_produto, ano)` mais um, mantendo o campo editável

#### Scenario: Comando rejeitado
- **WHEN** o firmware publica rejeição em até 3 segundos após `SET_BATCH`
- **THEN** o app exibe o motivo da rejeição e permanece na tela de configuração

#### Scenario: Nenhum produto cadastrado
- **WHEN** o operador abre a tela de lote e não há produtos no catálogo
- **THEN** o app exibe mensagem orientando cadastrar um produto em Cadastros antes de configurar o lote

#### Scenario: Operador não selecionado
- **WHEN** o operador tenta iniciar lote sem selecionar operador ativo
- **THEN** o app não envia `SET_BATCH` e destaca o seletor de operador
