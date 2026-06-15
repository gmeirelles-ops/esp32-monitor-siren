# zpl-label-layout Specification

## Purpose
TBD - created by archiving change nicelabel-zpl-calibration. Update Purpose after archive.
## Requirements
### Requirement: Stock 3-across 10×30 mm
O layout ZPL SHALL corresponder a rolo com 3 etiquetas por linha, cada etiqueta com 10 mm de altura e 30 mm de comprimento, resolução 203 dpi.

#### Scenario: Largura de linha em dots
- **WHEN** o gerador emite uma linha de etiquetas
- **THEN** `^PW` reflete a largura útil da linha inteira conforme ficha `stock-spec.md` (referência NiceLabel)

#### Scenario: Comprimento de linha em dots
- **WHEN** o gerador emite uma linha de etiquetas
- **THEN** `^LL` reflete o pitch vertical da linha conforme ficha `stock-spec.md`

### Requirement: Código de barras ITF 2 de 5
Cada etiqueta SHALL imprimir código de barras Interleaved 2 of 5 do serial de 10 dígitos e texto humano legível abaixo, com parâmetros alinhados ao export NiceLabel de referência.

#### Scenario: Simbologia ITF
- **WHEN** um serial válido de 10 dígitos é impresso
- **THEN** o ZPL contém comando `^BI` (ITF) com altura e módulo conforme referência NiceLabel

#### Scenario: Texto humano
- **WHEN** o barcode é impresso
- **THEN** o mesmo serial aparece em texto legível (`^A`) na posição Y documentada na referência

### Requirement: Posições das três colunas
O gerador SHALL posicionar campos na coluna 1, 2 e 3 com offsets X derivados do export NiceLabel (`^FO`), suportando 1 a 3 seriais por linha.

#### Scenario: Três seriais na linha
- **WHEN** `generateZplLabelRow` recebe 3 seriais
- **THEN** cada serial usa `^FO` na posição X da coluna correspondente conforme `zplColumnPositions` calibrado

#### Scenario: Uma coluna preenchida (reimpressão)
- **WHEN** `generateZplReprintRow` é chamado
- **THEN** apenas a coluna 1 contém barcode e texto; colunas 2 e 3 sem conteúdo, mantendo `^PW`/`^LL` da linha completa

