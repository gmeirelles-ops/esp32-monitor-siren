## MODIFIED Requirements

### Requirement: Formulário de configuração de lote
O app SHALL oferecer formulário para enviar `SET_BATCH` selecionando um produto cadastrado, preenchendo automaticamente `id_produto`, `tempo_teste`, `potencia_min` e `potencia_max`, solicitando ao operador `numero_op` e `quantidade_total`, derivando internamente `ano` e `proximo_sequencial`, e utilizando a bancada vinculada ao posto. A ação primária de início do lote SHALL ser rotulada **INICIAR**.

#### Scenario: Lote configurado a partir de produto cadastrado
- **WHEN** o operador seleciona produto, informa OP e quantidade e aciona INICIAR
- **THEN** o app monta `SET_BATCH` com ano e sequencial calculados automaticamente, envia via MQTT para a bancada vinculada e navega ao Batch Live Dashboard se aceito

#### Scenario: Rótulo do botão primário
- **WHEN** o operador visualiza a seção Ações na tela de Lote
- **THEN** o botão primário exibe o texto "INICIAR" (sem sufixo técnico SET_BATCH)

#### Scenario: Sequencial pré-preenchido internamente
- **WHEN** o operador seleciona um produto no formulário de lote
- **THEN** o app consulta `SerialCounters` para o par `(id_produto, ano_atual)` e usa `(último + 1)` como `proximo_sequencial` no payload, sem exibir o valor ao operador

#### Scenario: Ano derivado da data
- **WHEN** o app monta o payload `SET_BATCH` em qualquer dia do calendário
- **THEN** o campo `ano` corresponde aos dois últimos dígitos do ano civil local

#### Scenario: Comando rejeitado
- **WHEN** o firmware publica rejeição em até 3 segundos após `SET_BATCH`
- **THEN** o app exibe o motivo da rejeição e permanece na tela de configuração

#### Scenario: Nenhum produto cadastrado
- **WHEN** o operador abre a tela de lote e não há produtos no catálogo
- **THEN** o app exibe mensagem orientando cadastrar um produto na seção Cadastros antes de configurar o lote

#### Scenario: Bancada não vinculada
- **WHEN** o operador tenta iniciar lote sem bancada do posto definida
- **THEN** o app bloqueia o envio e direciona ao setup de bancada
