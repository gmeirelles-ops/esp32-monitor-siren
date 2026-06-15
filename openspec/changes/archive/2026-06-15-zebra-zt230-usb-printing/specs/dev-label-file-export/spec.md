## MODIFIED Requirements

### Requirement: Conteúdo do arquivo exportado
O arquivo exportado SHALL conter o ZPL gerado pelo mesmo pipeline usado para impressão em produção (`generateZplLabelRow` ou agrupamento equivalente do buffer corrente), independente do transporte configurado (USB, rede ou nenhum).

#### Scenario: Exportação com seriais no buffer
- **WHEN** o desenvolvedor aciona download e há seriais no buffer
- **THEN** o arquivo `.zpl` salvo contém comandos `^XA`…`^XZ` com os seriais do buffer selecionado

#### Scenario: Buffer vazio
- **WHEN** o desenvolvedor aciona download sem seriais no buffer
- **THEN** o app informa que não há conteúdo para exportar

## ADDED Requirements

### Requirement: Export ZPL como alternativa sem hardware
O app SHALL documentar na UI de desenvolvimento que o download de arquivo ZPL permite validar layout e conteúdo sem impressora USB ou rede conectada.

#### Scenario: Orientação em debug
- **WHEN** o desenvolvedor visualiza a ação de download em `kDebugMode`
- **THEN** texto de ajuda indica que o arquivo pode ser enviado manualmente à ZT230 (Zebra Setup Utilities) para teste de layout
