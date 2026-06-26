# batch-operator-ui Specification

## Purpose
Interface de operação de lote no app Flutter: configuração `SET_BATCH`, acompanhamento do último teste e encerramento `END_BATCH` por dispositivo.
## Requirements
### Requirement: Operador do lote definido pela sessão de login
O fluxo de lote SHALL utilizar o operador autenticado na sessão de login como operador ativo, sem exigir seleção manual adicional antes de configurar o lote.

#### Scenario: Início de lote com sessão ativa
- **WHEN** o operador autenticado abre a tela de Lote
- **THEN** o operador ativo já está definido conforme a sessão e o formulário de lote pode ser preenchido

#### Scenario: Troca de operador durante o turno
- **WHEN** o operador aciona troca de operador nas Configurações
- **THEN** a sessão é encerrada, o lote em andamento permanece no dispositivo, e novo operador deve autenticar-se na login

### Requirement: Formulário de configuração de lote
O app SHALL oferecer formulário para enviar `SET_BATCH` selecionando um produto cadastrado, preenchendo automaticamente `id_produto`, `tempo_teste`, `potencia_min` e `potencia_max`, solicitando ao operador `numero_op` e `quantidade_total`, derivando internamente `ano` (2 dígitos da data atual) e `proximo_sequencial` (contador local), e utilizando a bancada vinculada ao posto. O formulário SHALL NOT exibir campos editáveis para ano nem próximo sequencial.

#### Scenario: Lote configurado a partir de produto cadastrado
- **WHEN** o operador seleciona produto, informa OP e quantidade e confirma
- **THEN** o app monta `SET_BATCH` com ano e sequencial calculados automaticamente, envia via MQTT para a bancada vinculada e navega ao Batch Live Dashboard se aceito

#### Scenario: Sequencial pré-preenchido internamente
- **WHEN** o operador seleciona um produto no formulário de lote
- **THEN** o app consulta `SerialCounters` para o par `(id_produto, ano_atual)` e usa `(último + 1)` como `proximo_sequencial` no payload, sem exibir o valor ao operador

#### Scenario: Ano derivado da data
- **WHEN** o app monta o payload `SET_BATCH` em qualquer dia do calendário
- **THEN** o campo `ano` corresponde aos dois últimos dígitos do ano civil local (`DateTime.now().year % 100`)

#### Scenario: Comando rejeitado
- **WHEN** o firmware publica rejeição em até 3 segundos após `SET_BATCH`
- **THEN** o app exibe o motivo da rejeição e permanece na tela de configuração

#### Scenario: Nenhum produto cadastrado
- **WHEN** o operador abre a tela de lote e não há produtos no catálogo
- **THEN** o app exibe mensagem orientando cadastrar um produto na seção Cadastros antes de configurar o lote

#### Scenario: Bancada não vinculada
- **WHEN** o operador tenta configurar lote sem bancada do posto definida
- **THEN** o app bloqueia o envio e direciona ao setup de bancada

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

