# dev-label-file-export Specification

## Purpose
TBD - created by archiving change logout-on-exit-batch-retest-dev. Update Purpose after archive.
## Requirements
### Requirement: Download de arquivo ZPL apenas em desenvolvimento
O app SHALL oferecer ação para salvar em disco o conteúdo ZPL das etiquetas pendentes somente quando executado em modo de desenvolvimento (`kDebugMode`).

#### Scenario: Botão visível em debug
- **WHEN** o app roda em `kDebugMode` na tela de Etiquetas ou seção dev do lote
- **THEN** o app exibe ação "Baixar arquivo de impressão" (ou equivalente)

#### Scenario: Botão ausente em release
- **WHEN** o app roda em modo release
- **THEN** nenhuma ação de download de arquivo ZPL é exibida

### Requirement: Conteúdo do arquivo exportado
O arquivo exportado SHALL conter o ZPL gerado pelo mesmo pipeline usado para impressão em produção (`generateZplLabelRow` ou agrupamento equivalente do buffer corrente), calibrado conforme referência NiceLabel em `docs/label-reference/`.

#### Scenario: Exportação com seriais no buffer
- **WHEN** o desenvolvedor aciona download e há seriais no buffer
- **THEN** o arquivo `.zpl` salvo contém comandos `^XA`…`^XZ` com os seriais do buffer selecionado

#### Scenario: Buffer vazio
- **WHEN** o desenvolvedor aciona download sem seriais no buffer
- **THEN** o app informa que não há conteúdo para exportar

### Requirement: Nome e local do arquivo
O app SHALL sugerir nome de arquivo com identificação da OP e timestamp, e SHALL permitir ao usuário escolher o diretório de destino (diálogo nativo de salvar arquivo).

#### Scenario: Salvamento bem-sucedido
- **WHEN** o desenvolvedor confirma o diálogo de salvar
- **THEN** o arquivo é escrito no caminho escolhido e o app confirma sucesso em português

### Requirement: Export ZPL como alternativa sem hardware
O app SHALL documentar na UI de desenvolvimento que o download de arquivo ZPL permite validar layout e conteúdo sem impressora USB ou rede conectada.

#### Scenario: Orientação em debug
- **WHEN** o desenvolvedor visualiza a ação de download em `kDebugMode`
- **THEN** texto de ajuda indica que o arquivo pode ser enviado manualmente à ZT230 (Zebra Setup Utilities) para teste de layout

### Requirement: Comparação com referência NiceLabel
A documentação do export em desenvolvimento SHALL orientar o desenvolvedor a comparar o `.zpl` exportado com o arquivo de referência NiceLabel do repositório antes de homologar na impressora.

#### Scenario: Link para referência
- **WHEN** o desenvolvedor visualiza a ajuda do botão de download ZPL
- **THEN** o texto menciona `docs/label-reference/` e o procedimento de calibração NiceLabel

