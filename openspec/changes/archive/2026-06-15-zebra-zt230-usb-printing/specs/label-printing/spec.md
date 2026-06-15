## MODIFIED Requirements

### Requirement: Impressão em múltiplos de 3 etiquetas
O App Flutter SHALL enviar comandos ZPL à impressora Zebra ZT230 somente em múltiplos de 3 etiquetas, respeitando o rolo de 3 etiquetas por linha (10×30 mm), utilizando o transporte configurado (USB local via Windows RAW ou rede TCP na porta 9100).

#### Scenario: Buffer atinge múltiplo de 3
- **WHEN** o buffer de seriais aprovados atinge 3 etiquetas (ou múltiplo de 3)
- **THEN** o App Flutter envia o comando ZPL correspondente à impressora pelo transporte ativo e remove os seriais impressos do buffer

#### Scenario: Buffer abaixo de 3
- **WHEN** o buffer contém 1 ou 2 seriais e nenhum gatilho de fechamento foi acionado
- **THEN** o App Flutter não envia comando ZPL e mantém os seriais no buffer

### Requirement: Sinalização de falha de impressão
O app SHALL sinalizar ao operador toda falha de comunicação com a impressora (automática ou manual), indicando o modo de transporte ativo (USB ou rede), mantendo as etiquetas não impressas no buffer.

#### Scenario: Falha no auto-print
- **WHEN** a impressão automática de um bloco de 3 etiquetas falha
- **THEN** o app exibe alerta visível ao operador e mantém os seriais no buffer

#### Scenario: Falha visível na tela de Etiquetas
- **WHEN** existe uma falha de impressão registrada e não resolvida
- **THEN** a tela de Etiquetas exibe um aviso destacado com o erro

#### Scenario: Impressão bem-sucedida limpa o aviso
- **WHEN** uma impressão subsequente conclui com sucesso
- **THEN** o aviso de falha é removido

### Requirement: Busca e reimpressão de serial
O app SHALL permitir buscar um serial já validado no histórico local e reimprimir sua etiqueta, sem alterar o buffer de impressão corrente, emitindo sempre uma linha completa de 3 posições no rolo (serial na primeira coluna, demais colunas vazias) para preservar o alinhamento do rolo 3-across.

#### Scenario: Reimpressão de serial existente
- **WHEN** o operador busca um serial presente no histórico e aciona "Reimprimir"
- **THEN** o app envia à impressora ZPL de uma linha com o serial na coluna 1 e colunas 2–3 sem conteúdo, sem mexer no buffer de etiquetas pendentes

#### Scenario: Aviso de consumo de linha na reimpressão
- **WHEN** o operador confirma reimpressão de um serial avulso
- **THEN** o app informa que a impressora avançará uma linha inteira (3 posições físicas, sendo 2 em branco)

#### Scenario: Serial inexistente
- **WHEN** o operador busca um serial que não consta no histórico local
- **THEN** o app informa que o serial não foi encontrado e não envia comando de impressão

#### Scenario: Busca parcial
- **WHEN** o operador digita parte de um serial
- **THEN** o app sugere seriais do histórico que contêm o trecho digitado

### Requirement: Exportação de arquivo ZPL em desenvolvimento
O app SHALL permitir salvar em arquivo o ZPL que seria enviado à impressora, exclusivamente em builds de desenvolvimento, sem substituir o fluxo de impressão USB ou rede em produção.

#### Scenario: Export não altera buffer
- **WHEN** o desenvolvedor exporta o ZPL do buffer corrente
- **THEN** os seriais permanecem no buffer e nenhum comando é enviado à impressora

#### Scenario: ZPL idêntico ao da impressão
- **WHEN** o desenvolvedor exporta um bloco de três seriais
- **THEN** o conteúdo do arquivo é byte-a-byte equivalente ao ZPL que seria transmitido ao transporte de impressão ativo
