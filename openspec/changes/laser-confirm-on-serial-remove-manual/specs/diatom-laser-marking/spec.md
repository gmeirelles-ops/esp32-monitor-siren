## MODIFIED Requirements

### Requirement: Servidor TCP entrega serial e conclui a fila
O app SHALL atuar como **servidor TCP** na porta configurada. Quando o DiatuCAD conecta e envia o comando de serial configurado, o app SHALL responder com o próximo serial ITF pendente na fila `mark_queue` e SHALL marcar essa entrada como `delivered` na mesma operação (removendo-a da fila pendente/exibida). Se o comando não corresponder ao configurado, o app SHALL responder `ERROR:BADCMD`. Se não houver serial pendente, SHALL responder `ERROR:EMPTY`. O matching de comando SHALL ignorar caracteres `\r` e `\n` e espaços nas extremidades.

#### Scenario: F2 puxa serial e limpa a fila
- **WHEN** há ao menos um serial `pending` e o DiatuCAD envia o comando de serial
- **THEN** o app responde com o serial ITF e a entrada fica `delivered` (some da tela Gravação / painel de gravação)

#### Scenario: Comando inválido
- **WHEN** o payload TCP não corresponde ao comando de serial nem ao de modelo
- **THEN** o app responde `ERROR:BADCMD` e não altera a fila

#### Scenario: Fila vazia
- **WHEN** não há entradas `pending` e o DiatuCAD pede serial
- **THEN** o app responde `ERROR:EMPTY`

### Requirement: Pedido de modelo não consome a fila
Quando o DiatuCAD envia o comando de modelo configurado, o app SHALL responder com o `nome` do produto correspondente ao serial ativo ou ao último serial entregue nesta sessão, e SHALL NOT alterar o status da fila `mark_queue`.

#### Scenario: Modelo após serial
- **WHEN** o app acabou de entregar um serial e o DiatuCAD pede modelo
- **THEN** o app responde com `Products.nome` do `idProduto` embutido no serial e a fila permanece inalterada

### Requirement: Sem canal TCP de manual
O servidor TCP do app SHALL NOT expor comando, rota ou resposta dedicados a “manual do produto”. Preferências e UI de comando `laser_manual_command` SHALL ser removidas do fluxo operacional.

#### Scenario: Objeto manual legado no job
- **WHEN** o DiatuCAD envia um comando que não é serial nem modelo (ex. antigo `TCP: manual`)
- **THEN** o app responde `ERROR:BADCMD`
