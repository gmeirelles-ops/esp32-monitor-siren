## ADDED Requirements

### Requirement: Build release Windows automatizado

O repositório SHALL fornecer script `scripts/build_windows_release.ps1` que, em ambiente Windows com Flutter SDK e Visual Studio C++, executa `flutter pub get`, gera código Drift (`build_runner`) e `flutter build windows --release`.

#### Scenario: Build bem-sucedido no Windows
- **WHEN** o operador executa `.\scripts\build_windows_release.ps1` em máquina Windows com toolchain válida
- **THEN** o diretório `sirene_app/build/windows/x64/runner/Release/` é produzido sem erro

#### Scenario: Tentativa no Linux
- **WHEN** o desenvolvedor executa `scripts/build_windows_release.sh` em Linux
- **THEN** o script falha com mensagem indicando que o build Windows requer Windows ou CI `windows-latest`

### Requirement: Pacote portátil para pendrive

O script de release SHALL montar a pasta `dist/DipontoSireneValidator-<versão>-win64/` contendo subpasta `app/` com **todo** o conteúdo de `Release/`, arquivo `LEIA-ME.txt` e launcher `Iniciar Diponto Sirene Validator.bat` que inicia `app\sirene_app.exe`.

#### Scenario: Estrutura do pacote
- **WHEN** o build de release conclui
- **THEN** existem `LEIA-ME.txt`, o launcher `.bat` e `app/sirene_app.exe` com `app/data/` no pacote

#### Scenario: ZIP para transporte
- **WHEN** o empacotamento termina
- **THEN** um arquivo `dist/DipontoSireneValidator-<versão>-win64.zip` é gerado com a mesma estrutura da pasta

#### Scenario: Versão no nome do artefato
- **WHEN** `pubspec.yaml` declara `version: 1.0.0+1`
- **THEN** o nome do pacote usa `1.0.0` (parte antes do `+`)

### Requirement: Instruções de primeiro uso no pacote

O arquivo `LEIA-ME.txt` SHALL estar em português e documentar: pré-requisitos (Windows 10/11 x64, VC++ Redistributable), como iniciar pelo `.bat`, configuração de MQTT e impressora, e que dados SQLite ficam no perfil do usuário (não no pendrive).

#### Scenario: Operador abre pendrive pela primeira vez
- **WHEN** extrai o ZIP e lê `LEIA-ME.txt`
- **THEN** encontra passos para executar o app e configurar o posto sem clonar o repositório

### Requirement: Artefato CI Windows

O pipeline CI SHALL incluir job em `windows-latest` acionável por `workflow_dispatch` que executa o script de release e publica o ZIP como artifact do GitHub Actions.

#### Scenario: Download do CI
- **WHEN** um mantenedor dispara o workflow manualmente e o job conclui
- **THEN** o artifact `DipontoSireneValidator-*-win64.zip` está disponível para download
