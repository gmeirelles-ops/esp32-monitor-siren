## MODIFIED Requirements

### Requirement: Impressão em múltiplos de 3 etiquetas
O App Flutter SHALL enviar comandos ZPL à impressora Zebra ZT230 somente em múltiplos de 3 etiquetas, respeitando o rolo de 3 etiquetas por linha (10×30 mm) calibrado contra referência NiceLabel, utilizando o transporte configurado (USB local via Windows RAW ou rede TCP na porta 9100).

#### Scenario: Buffer atinge múltiplo de 3
- **WHEN** o buffer de seriais aprovados atinge 3 etiquetas (ou múltiplo de 3)
- **THEN** o App Flutter envia o comando ZPL correspondente à impressora pelo transporte ativo e remove os seriais impressos do buffer

#### Scenario: Buffer abaixo de 3
- **WHEN** o buffer contém 1 ou 2 seriais e nenhum gatilho de fechamento foi acionado
- **THEN** o App Flutter não envia comando ZPL e mantém os seriais no buffer

### Requirement: Exportação de arquivo ZPL em desenvolvimento
O app SHALL permitir salvar em arquivo o ZPL que seria enviado à impressora, exclusivamente em builds de desenvolvimento, sem substituir o fluxo de impressão USB ou rede em produção; a documentação em dev SHALL referenciar o arquivo de referência NiceLabel para comparação de layout.

#### Scenario: Export não altera buffer
- **WHEN** o desenvolvedor exporta o ZPL do buffer corrente
- **THEN** os seriais permanecem no buffer e nenhum comando é enviado à impressora

#### Scenario: ZPL idêntico ao da impressão
- **WHEN** o desenvolvedor exporta um bloco de três seriais
- **THEN** o conteúdo do arquivo é byte-a-byte equivalente ao ZPL que seria transmitido ao transporte de impressão ativo

#### Scenario: Referência NiceLabel documentada
- **WHEN** o desenvolvedor usa export ZPL em `kDebugMode`
- **THEN** texto de ajuda indica comparar com `docs/label-reference/` (ZPL exportado do NiceLabel)
