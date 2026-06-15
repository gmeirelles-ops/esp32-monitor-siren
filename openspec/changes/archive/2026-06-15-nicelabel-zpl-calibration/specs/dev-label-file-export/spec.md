## MODIFIED Requirements

### Requirement: Conteúdo do arquivo exportado
O arquivo exportado SHALL conter o ZPL gerado pelo mesmo pipeline usado para impressão em produção (`generateZplLabelRow` ou agrupamento equivalente do buffer corrente), calibrado conforme referência NiceLabel em `docs/label-reference/`.

#### Scenario: Exportação com seriais no buffer
- **WHEN** o desenvolvedor aciona download e há seriais no buffer
- **THEN** o arquivo `.zpl` salvo contém comandos `^XA`…`^XZ` com os seriais do buffer selecionado

#### Scenario: Buffer vazio
- **WHEN** o desenvolvedor aciona download sem seriais no buffer
- **THEN** o app informa que não há conteúdo para exportar

## ADDED Requirements

### Requirement: Comparação com referência NiceLabel
A documentação do export em desenvolvimento SHALL orientar o desenvolvedor a comparar o `.zpl` exportado com o arquivo de referência NiceLabel do repositório antes de homologar na impressora.

#### Scenario: Link para referência
- **WHEN** o desenvolvedor visualiza a ajuda do botão de download ZPL
- **THEN** o texto menciona `docs/label-reference/` e o procedimento de calibração NiceLabel
