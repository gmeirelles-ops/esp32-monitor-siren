# artigo-iot-formatacao Specification

## Purpose
TBD - created by archiving change audit-artigo-iot-formatacao. Update Purpose after archive.
## Requirements
### Requirement: Documento baseado no template ANEXO 5A

O artigo gerado SHALL ser produzido a partir de uma cópia do arquivo `ANEXO 5A - MODELO DE ARTIGO - AUTOR ÚNICO (2).docx`, preservando estilos Word, margens e quebras de seção do modelo.

#### Scenario: Estilos do modelo preservados

- **WHEN** o script de geração produz `ARTIGO - IoT (revisado).docx`
- **THEN** o documento MUST conter os estilos customizados do modelo (`paper title`, `Abstract`, `Keywords`, `Heading 1`, `Heading 2`, `Body Text`, `references`, `table head`, `figure caption`, `02 - Citação longa`)

#### Scenario: Margens conforme modelo

- **WHEN** as margens do documento gerado são inspecionadas
- **THEN** a primeira seção MUST ter margens laterais de 1,58 cm e margem superior de 2,25 cm (tolerância ±0,05 cm)

### Requirement: Estrutura de autoria autor único

O artigo SHALL apresentar autoria no formato de autor único com orientador, em tabela de duas colunas conforme o modelo.

#### Scenario: Autor e orientador na tabela

- **WHEN** a tabela de autoria é lida
- **THEN** a coluna esquerda MUST conter Gabriel da Silva Meirelles (autor) com curso, faculdade, cidade e e-mail
- **THEN** a coluna direita MUST conter Dirlei Ernane Bagestão (orientador) com curso, faculdade, cidade e e-mail

#### Scenario: Sem coautoria equivalente

- **WHEN** a estrutura de autoria é validada
- **THEN** Dirlei Ernane Bagestão MUST NOT aparecer como coautor na mesma posição hierárquica do autor

### Requirement: Resumo e palavras-chave conforme normas

O resumo SHALL seguir as regras editoriais do ANEXO 5A.

#### Scenario: Formato do resumo

- **WHEN** o parágrafo de resumo é lido
- **THEN** MUST iniciar com `Resumo—` (travessão sem espaços antes ou depois do hífen)
- **THEN** MUST usar o estilo Word `Abstract`
- **THEN** MUST ter entre 100 e 250 palavras em um único parágrafo

#### Scenario: Resumo sem siglas

- **WHEN** o texto do resumo é analisado
- **THEN** MUST NOT conter siglas ou acrônimos (ex.: IoT, ESP32, MQTT, PZEM)

#### Scenario: Palavras-chave

- **WHEN** o parágrafo de palavras-chave é lido
- **THEN** MUST usar o estilo Word `Keywords`
- **THEN** MUST conter entre 3 e 5 termos separados por vírgula
- **THEN** MUST iniciar com `Palavras-chave:` seguido dos termos em letras minúsculas

### Requirement: Elementos proibidos pelo modelo

O artigo gerado SHALL NOT incluir elementos ausentes no ANEXO 5A.

#### Scenario: Sem cabeçalho institucional extra

- **WHEN** os primeiros parágrafos do documento são lidos
- **THEN** MUST NOT conter o bloco de recredenciamento/credenciamento SENAI antes do título

#### Scenario: Sem abstract em inglês

- **WHEN** o documento é varrido
- **THEN** MUST NOT conter parágrafos iniciando com `Abstract` ou `Keywords:` em inglês

#### Scenario: Sem paginação

- **WHEN** os rodapés são inspecionados
- **THEN** MUST NOT conter campos de número de página

### Requirement: Hierarquia de títulos e corpo

As seções do artigo SHALL usar a hierarquia de estilos do modelo.

#### Scenario: Títulos de seção principais

- **WHEN** as seções Introdução, Referencial Teórico, Procedimento Metodológico, Aplicações e Resultados e Conclusão são lidas
- **THEN** cada uma MUST usar o estilo `Heading 1`
- **THEN** MUST estar em sentence case (ex.: `Introdução`, não `INTRODUÇÃO`)

#### Scenario: Subseções do referencial

- **WHEN** subseções como Microcontrolador ESP32, Sensor PZEM-004T, Protocolo MQTT e Automação na Indústria são lidas
- **THEN** cada uma MUST usar o estilo `Heading 2`

#### Scenario: Corpo do texto

- **WHEN** parágrafos de conteúdo principal são lidos
- **THEN** MUST usar o estilo `Body Text` (justificado, com recuo de primeira linha)

### Requirement: Citações, figuras, tabelas e referências

Elementos especiais SHALL seguir convenções do modelo IEEE/SENAI.

#### Scenario: Citação longa

- **WHEN** a citação direta de Groover é inserida
- **THEN** MUST usar o estilo `02 - Citação longa`
- **THEN** a referência `(GROOVER, 2019, p. 45).` MUST aparecer em parágrafo `Body Text` separado

#### Scenario: Legendas de figuras

- **WHEN** figuras são referenciadas no texto
- **THEN** as legendas MUST usar abreviação `Fig. N.` (não `Figura N`)
- **THEN** MUST usar o estilo `figure caption`

#### Scenario: Tabela com numeração romana

- **WHEN** a tabela de comparação de medições é inserida
- **THEN** o título MUST usar numeração romana (`Tabela I`)
- **THEN** MUST usar o estilo `table head`

#### Scenario: Referências bibliográficas

- **WHEN** a seção de referências é lida
- **THEN** o título MUST usar o estilo `Heading 5` com texto `Referências`
- **THEN** cada entrada MUST usar o estilo `references`
- **THEN** MUST conter as 8 referências ABNT já definidas no artigo revisado

### Requirement: Auditoria automatizada de conformidade

O repositório SHALL incluir verificação automatizada da formatação do artigo.

#### Scenario: Script de auditoria detecta violações

- **WHEN** `scripts/audit_artigo_formatacao.py` é executado contra um documento não conforme
- **THEN** MUST listar cada violação encontrada
- **THEN** MUST retornar código de saída diferente de zero

#### Scenario: Artigo conforme passa na auditoria

- **WHEN** `scripts/audit_artigo_formatacao.py` é executado após geração correta
- **THEN** MUST retornar código de saída zero
- **THEN** MUST reportar conformidade com o ANEXO 5A

