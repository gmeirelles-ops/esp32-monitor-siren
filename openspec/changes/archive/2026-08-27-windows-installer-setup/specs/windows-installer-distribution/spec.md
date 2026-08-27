## ADDED Requirements

### Requirement: Instalador Windows Inno Setup

O repositório SHALL fornecer script Inno Setup (`scripts/windows-installer/DipontoSireneValidator.iss`) e `scripts/build_windows_installer.ps1` que produz `dist/DipontoSireneValidator-<versão>-setup.exe` a partir do output de `flutter build windows --release`.

#### Scenario: Build do instalador no Windows
- **WHEN** o mantenedor executa `build_windows_installer.ps1` com Flutter, Visual Studio C++ e Inno Setup 6 instalados
- **THEN** o arquivo `dist/DipontoSireneValidator-<versão>-setup.exe` é gerado sem erro

#### Scenario: Versão alinhada ao pubspec
- **WHEN** `pubspec.yaml` declara `version: 1.0.0+1`
- **THEN** o nome do setup e metadados do instalador usam `1.0.0`

### Requirement: Experiência de instalação no posto

O instalador SHALL copiar todos os arquivos de `Release/` (incluindo `data/`), criar atalho no Menu Iniciar com nome "Diponto Sirene Validator" e registrar desinstalador em "Apps e recursos".

#### Scenario: Instalação completa
- **WHEN** o operador executa o setup e conclui o wizard
- **THEN** o app inicia a partir do atalho do Menu Iniciar e `data/` está presente ao lado de `sirene_app.exe`

#### Scenario: Atalho opcional na área de trabalho
- **WHEN** o usuário marca a opção de atalho na área de trabalho no wizard
- **THEN** um atalho é criado na área de trabalho apontando para `sirene_app.exe`

#### Scenario: Desinstalação
- **WHEN** o usuário desinstala pelo Painel de Controle / Configurações
- **THEN** os arquivos em Program Files são removidos (dados em `%APPDATA%` permanecem)

### Requirement: Upgrade por reinstalação

O instalador SHALL permitir instalar sobre uma versão anterior (mesmo diretório) sem exigir desinstalação manual prévia.

#### Scenario: Upgrade in-place
- **WHEN** uma versão anterior já está instalada e o usuário executa um setup mais recente
- **THEN** a instalação conclui substituindo binários mantendo configuração local do app

### Requirement: Artifact CI do instalador

O job CI `windows-release` SHALL publicar o `setup.exe` como artifact adicional ao ZIP portátil existente.

#### Scenario: Download do setup pelo GitHub Actions
- **WHEN** o workflow manual conclui com sucesso
- **THEN** o artifact inclui `DipontoSireneValidator-*-setup.exe` disponível para download
