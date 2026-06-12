# label-printing Specification

## Purpose
Impressão de etiquetas Zebra no app Flutter: geração ZPL, buffer de seriais aprovados e envio à impressora de rede configurada no posto.
## Requirements
### Requirement: Acúmulo de seriais aprovados em buffer
O App Flutter SHALL acumular em um buffer local os números de série aprovados antes de emitir comandos de impressão.

#### Scenario: Serial aprovado adicionado ao buffer
- **WHEN** uma sirene é aprovada e seu serial completo é gerado
- **THEN** o App Flutter adiciona o serial ao buffer local de impressão

### Requirement: Impressão em múltiplos de 3 etiquetas
O App Flutter SHALL enviar comandos ZPL à impressora Zebra ZT230 somente em múltiplos de 3 etiquetas, respeitando o rolo de 3 etiquetas por linha (10x30 mm).

#### Scenario: Buffer atinge múltiplo de 3
- **WHEN** o buffer de seriais aprovados atinge 3 etiquetas (ou múltiplo de 3)
- **THEN** o App Flutter envia o comando ZPL correspondente à impressora e remove os seriais impressos do buffer

#### Scenario: Buffer abaixo de 3
- **WHEN** o buffer contém 1 ou 2 seriais e nenhum gatilho de fechamento foi acionado
- **THEN** o App Flutter não envia comando ZPL e mantém os seriais no buffer

### Requirement: Gatilho manual para etiquetas órfãs
O App Flutter SHALL oferecer um gatilho manual de fechamento de lote que force a impressão das etiquetas restantes, removendo do buffer somente as entradas efetivamente impressas.

#### Scenario: Fechamento de lote com órfãs
- **WHEN** o operador aciona o gatilho de fechamento e há 1 ou 2 seriais no buffer
- **THEN** o App Flutter envia o comando ZPL para imprimir as etiquetas restantes e remove do buffer apenas as entradas impressas

#### Scenario: Aprovação durante impressão manual não é perdida
- **WHEN** um novo serial aprovado entra no buffer enquanto uma impressão manual está em andamento
- **THEN** a nova entrada permanece no buffer após a conclusão da impressão

#### Scenario: Falha parcial preserva não impressas
- **WHEN** a impressora falha após imprimir parte dos blocos
- **THEN** somente as etiquetas dos blocos enviados com sucesso são removidas do buffer

### Requirement: Busca e reimpressão de serial
O app SHALL permitir buscar um serial já validado no histórico local e reimprimir sua etiqueta individual, sem alterar o buffer de impressão corrente.

#### Scenario: Reimpressão de serial existente
- **WHEN** o operador busca um serial presente no histórico e aciona "Reimprimir"
- **THEN** o app envia à impressora o ZPL da etiqueta individual desse serial, sem mexer no buffer de etiquetas pendentes

#### Scenario: Serial inexistente
- **WHEN** o operador busca um serial que não consta no histórico local
- **THEN** o app informa que o serial não foi encontrado e não envia comando de impressão

#### Scenario: Busca parcial
- **WHEN** o operador digita parte de um serial
- **THEN** o app sugere seriais do histórico que contêm o trecho digitado

### Requirement: Sinalização de falha de impressão
O app SHALL sinalizar ao operador toda falha de comunicação com a impressora (automática ou manual), mantendo as etiquetas não impressas no buffer.

#### Scenario: Falha no auto-print
- **WHEN** a impressão automática de um bloco de 3 etiquetas falha
- **THEN** o app exibe alerta visível ao operador e mantém os seriais no buffer

#### Scenario: Falha visível na tela de Etiquetas
- **WHEN** existe uma falha de impressão registrada e não resolvida
- **THEN** a tela de Etiquetas exibe um aviso destacado com o erro

#### Scenario: Impressão bem-sucedida limpa o aviso
- **WHEN** uma impressão subsequente conclui com sucesso
- **THEN** o aviso de falha é removido

### Requirement: Buffer de etiquetas reativo na UI
A tela de Etiquetas SHALL refletir automaticamente inserções e remoções no buffer local, incluindo o contador do badge, sem exigir navegação ou recarga manual.

#### Scenario: Novo serial no buffer
- **WHEN** um serial aprovado é adicionado ao buffer enquanto a tela de Etiquetas está aberta
- **THEN** a lista e o contador do badge são atualizados imediatamente

#### Scenario: Impressão remove entradas
- **WHEN** um bloco de etiquetas é impresso com sucesso e removido do buffer
- **THEN** a lista na tela de Etiquetas reflete a remoção sem recarregar a tela

### Requirement: Buffer de etiquetas agrupado por lote (OP)
A tela de Etiquetas SHALL exibir o buffer pendente agrupado por `numero_op` (lote), com cada grupo expansível mostrando a lista de seriais daquele lote.

#### Scenario: Múltiplos lotes no buffer
- **WHEN** o buffer contém seriais de duas OPs distintas
- **THEN** a tela exibe duas seções de lote, cada uma com cabeçalho identificando a OP e a quantidade de etiquetas pendentes

#### Scenario: Expansão de um lote
- **WHEN** o operador expande um grupo de lote
- **THEN** o app lista os seriais daquele lote com código e horário de inclusão no buffer

#### Scenario: Um único lote
- **WHEN** todas as etiquetas pendentes pertencem à mesma OP
- **THEN** a tela exibe um único grupo com todas as etiquetas

### Requirement: Impressão contextual por lote
A tela de Etiquetas SHALL oferecer ação de impressão das etiquetas pendentes de um lote específico, aplicando as mesmas regras de múltiplos de 3 e remoção parcial do buffer.

#### Scenario: Imprimir apenas um lote
- **WHEN** o operador aciona "Imprimir lote" em um grupo com 4 etiquetas da OP X
- **THEN** o app envia ZPL apenas para as etiquetas da OP X e remove do buffer somente as impressas com sucesso

#### Scenario: Aviso de órfãs por lote
- **WHEN** um grupo de lote possui quantidade de etiquetas que não é múltiplo de 3
- **THEN** o cabeçalho do grupo indica quantas etiquetas órfãs aguardam fechamento ou próximo múltiplo de 3

