## MODIFIED Requirements

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

## ADDED Requirements

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
