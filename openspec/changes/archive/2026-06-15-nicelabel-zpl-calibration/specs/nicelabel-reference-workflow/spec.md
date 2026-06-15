## ADDED Requirements

### Requirement: Checklist de extração NiceLabel
O projeto SHALL documentar checklist do que extrair do NiceLabel Designer para calibrar etiquetas: stock (10×30 mm, 3 colunas, gaps), DPI 203, propriedades do barcode ITF e export ZPL com serial de teste fixo.

#### Scenario: Guia disponível no repositório
- **WHEN** um desenvolvedor ou operador precisa calibrar o layout da etiqueta
- **THEN** encontra em `docs/label-reference/` o passo a passo e a lista de campos a anotar no NiceLabel

#### Scenario: Serial de teste padronizado
- **WHEN** o ZPL é exportado do NiceLabel para referência
- **THEN** usa o serial de exemplo `1232600196` (ou outro documentado na ficha) para comparação com o gerador do app

### Requirement: Artefatos de referência versionados
O repositório SHALL conter ZPL exportado do NiceLabel e ficha de medidas do stock (`stock-spec.md`) commitados em `docs/label-reference/`.

#### Scenario: ZPL de referência presente
- **WHEN** a calibração é concluída
- **THEN** existe pelo menos um arquivo `.zpl` de linha 3-across exportado do NiceLabel no diretório de referência

#### Scenario: Ficha de medidas
- **WHEN** o stock é definido no NiceLabel
- **THEN** `stock-spec.md` registra largura, altura, colunas, gaps e DPI anotados do Label Setup
