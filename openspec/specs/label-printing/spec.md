# label-printing Specification

## Purpose
TBD - created by archiving change validacao-sirenes. Update Purpose after archive.
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
O App Flutter SHALL oferecer um gatilho manual de fechamento de lote que force a impressão das etiquetas órfãs restantes (1 ou 2).

#### Scenario: Fechamento de lote com órfãs
- **WHEN** o operador aciona o gatilho de fechamento e há 1 ou 2 seriais no buffer
- **THEN** o App Flutter envia o comando ZPL para imprimir as etiquetas restantes e esvazia o buffer

