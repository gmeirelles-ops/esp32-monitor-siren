## ADDED Requirements

### Requirement: Exportação de arquivo ZPL em desenvolvimento
O app SHALL permitir salvar em arquivo o ZPL que seria enviado à impressora, exclusivamente em builds de desenvolvimento, sem substituir o fluxo de impressão em rede em produção.

#### Scenario: Export não altera buffer
- **WHEN** o desenvolvedor exporta o ZPL do buffer corrente
- **THEN** os seriais permanecem no buffer e nenhum comando é enviado à impressora

#### Scenario: ZPL idêntico ao da impressão
- **WHEN** o desenvolvedor exporta um bloco de três seriais
- **THEN** o conteúdo do arquivo é byte-a-byte equivalente ao ZPL que seria transmitido via TCP à impressora
