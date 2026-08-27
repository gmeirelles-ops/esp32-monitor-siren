## MODIFIED Requirements

### Requirement: Pacote portátil para pendrive

O script de release SHALL montar a pasta `dist/DipontoSireneValidator-<versão>-win64/` contendo subpasta `app/` com **todo** o conteúdo de `Release/`, arquivo `LEIA-ME.txt` e launcher `Iniciar Diponto Sirene Validator.bat` que inicia `app\sirene_app.exe`. O pipeline de release SHALL **também** produzir instalador Inno Setup (`*-setup.exe`) para deploy fixo no PC do posto.

#### Scenario: Estrutura do pacote
- **WHEN** o build de release conclui
- **THEN** existem `LEIA-ME.txt`, o launcher `.bat` e `app/sirene_app.exe` com `app/data/` no pacote

#### Scenario: ZIP para transporte
- **WHEN** o empacotamento termina
- **THEN** um arquivo `dist/DipontoSireneValidator-<versão>-win64.zip` é gerado com a mesma estrutura da pasta

#### Scenario: Versão no nome do artefato
- **WHEN** `pubspec.yaml` declara `version: 1.0.0+1`
- **THEN** o nome do pacote usa `1.0.0` (parte antes do `+`)

#### Scenario: Setup para PC fixo
- **WHEN** o pipeline de release Windows conclui
- **THEN** `dist/DipontoSireneValidator-<versão>-setup.exe` está disponível além do ZIP portátil

### Requirement: Artefato CI Windows

O pipeline CI SHALL incluir job em `windows-latest` acionável por `workflow_dispatch` que executa o script de release e publica o ZIP **e** o instalador `.exe` como artifacts do GitHub Actions.

#### Scenario: Download do CI
- **WHEN** um mantenedor dispara o workflow manualmente e o job conclui
- **THEN** os artifacts `DipontoSireneValidator-win64.zip` e `DipontoSireneValidator-setup.exe` estão disponíveis para download
