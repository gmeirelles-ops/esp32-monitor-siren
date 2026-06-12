## ADDED Requirements

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
