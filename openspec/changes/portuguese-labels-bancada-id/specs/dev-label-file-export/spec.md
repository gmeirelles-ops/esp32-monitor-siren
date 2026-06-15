## MODIFIED Requirements

### Requirement: Download de arquivo ZPL apenas em desenvolvimento
O app SHALL oferecer ação **"Baixar arquivo ZPL"** para salvar em disco o conteúdo ZPL das etiquetas pendentes somente quando executado em modo de desenvolvimento (`kDebugMode`).

#### Scenario: Botão visível em debug
- **WHEN** o app roda em `kDebugMode` na tela de Etiquetas
- **THEN** o app exibe ação "Baixar arquivo ZPL" com extensão `.zpl` no diálogo de salvar

#### Scenario: Botão ausente em release
- **WHEN** o app roda em modo release
- **THEN** nenhuma ação de download de arquivo ZPL é exibida

### Requirement: Conteúdo do arquivo exportado
O arquivo exportado SHALL ser texto ZPL válido (`^XA`…`^XZ`), gerado pelo mesmo pipeline de impressão, concatenando blocos de até 3 seriais quando o buffer contiver mais de 3 etiquetas.

#### Scenario: Exportação com seis seriais no buffer
- **WHEN** o desenvolvedor baixa o ZPL e há seis seriais no buffer
- **THEN** o arquivo `.zpl` contém dois blocos `^XA`…`^XZ` equivalentes aos enviados à impressora

#### Scenario: Buffer vazio
- **WHEN** o desenvolvedor aciona download sem seriais no buffer
- **THEN** o app informa em português que não há conteúdo para exportar

### Requirement: Nome e local do arquivo
O app SHALL sugerir nome `etiquetas_<OP>_<timestamp>.zpl` e permitir escolher o diretório de destino.

#### Scenario: Salvamento bem-sucedido
- **WHEN** o desenvolvedor confirma o diálogo de salvar
- **THEN** o arquivo é escrito com extensão `.zpl` e o app confirma sucesso em português
