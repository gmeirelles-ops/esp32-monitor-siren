## MODIFIED Requirements

### Requirement: Impressão em múltiplos de 3 etiquetas
O App Flutter SHALL enviar comandos ZPL à impressora Zebra ZT230 somente em múltiplos de 3 etiquetas quando o **modo de marcação** estiver configurado como `Etiquetas (Zebra)`. Quando o modo for `Gravação laser (Diatom)`, este requisito SHALL NOT aplicar.

#### Scenario: Buffer atinge múltiplo de 3 (modo etiquetas)
- **WHEN** o modo é Etiquetas e o buffer de seriais aprovados atinge 3 etiquetas (ou múltiplo de 3)
- **THEN** o App Flutter envia o comando ZPL correspondente à impressora pelo transporte ativo e remove os seriais impressos do buffer

#### Scenario: Modo laser ativo
- **WHEN** o modo é Gravação laser e um serial é aprovado
- **THEN** o app não envia ZPL automático por múltiplos de 3

#### Scenario: Buffer abaixo de 3 (modo etiquetas)
- **WHEN** o modo é Etiquetas, o buffer contém 1 ou 2 seriais e nenhum gatilho de fechamento foi acionado
- **THEN** o App Flutter não envia comando ZPL e mantém os seriais no buffer

### Requirement: Busca e reimpressão de serial
O app SHALL permitir buscar um serial já validado no histórico local e reimprimir sua etiqueta quando modo Etiquetas estiver ativo, ou regravar no laser quando modo Gravação laser estiver ativo, sem alterar o buffer corrente.

#### Scenario: Reimpressão de serial existente (etiquetas)
- **WHEN** o modo é Etiquetas, o operador busca um serial presente no histórico e aciona "Reimprimir"
- **THEN** o app envia à impressora ZPL de uma linha com o serial na coluna 1 e colunas 2–3 sem conteúdo, sem mexer no buffer de etiquetas pendentes

#### Scenario: Regravação (laser)
- **WHEN** o modo é Gravação laser e o operador aciona regravação de serial do histórico
- **THEN** o app envia o serial ao laser Diatom via TCP

#### Scenario: Aviso de consumo de linha na reimpressão
- **WHEN** o operador confirma reimpressão de um serial avulso no modo Etiquetas
- **THEN** o app informa que a impressora avançará uma linha inteira (3 posições físicas, sendo 2 em branco)

#### Scenario: Serial inexistente
- **WHEN** o operador busca um serial que não consta no histórico local
- **THEN** o app informa que o serial não foi encontrado e não envia comando de impressão ou gravação

#### Scenario: Busca parcial
- **WHEN** o operador digita parte de um serial
- **THEN** o app sugere seriais do histórico que contêm o trecho digitado
