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

