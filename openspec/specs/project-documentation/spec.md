# project-documentation Specification

## Purpose
TBD - created by archiving change project-docs-and-gitignore. Update Purpose after archive.
## Requirements
### Requirement: README de repositório
O repositório SHALL conter `README.md` na raiz descrevendo o propósito do monorepo, estrutura de diretórios, pré-requisitos e comandos para executar testes locais.

#### Scenario: Novo desenvolvedor onboarding
- **WHEN** um desenvolvedor clona o repositório
- **THEN** o README orienta onde estão firmware, app, specs e como rodar `flutter test` e host tests

#### Scenario: Link para produção
- **WHEN** o README referencia operação em fábrica
- **THEN** aponta para `docs/PRODUCAO.md` com checklist de deploy

### Requirement: Exclusão de artefatos de build
O repositório SHALL conter `.gitignore` que exclui diretórios de build Flutter, ESP-IDF, dependências Node locais e arquivos de IDE/OS.

#### Scenario: Build local não aparece no git status
- **WHEN** o desenvolvedor compila firmware ou app Flutter
- **THEN** artefatos em `build/`, `.dart_tool/` e `sirene-validator/build/` são ignorados pelo Git

### Requirement: Documentação de distribuição Windows portátil

A documentação de produção SHALL descrever como gerar o pacote portátil, copiar para pendrive, extrair no PC do posto e validar com smoke test mínimo (app abre, MQTT configurável, tela Lote visível).

#### Scenario: Checklist pendrive em PRODUCAO.md
- **WHEN** o supervisor consulta `docs/PRODUCAO.md`
- **THEN** encontra seção com comandos `build_windows_release.ps1`, estrutura do ZIP e passos pós-extração

#### Scenario: README do app referencia pendrive
- **WHEN** o desenvolvedor lê `sirene_app/README.md`
- **THEN** encontra link para script de release e limitação de build apenas em Windows/CI



### Requirement: Versões documentadas batem com o código
A documentação operacional SHALL citar `FIRMWARE_VERSION` do firmware e a versão do app em `pubspec.yaml`.

#### Scenario: Guia firmware
- **WHEN** um integrador abre `GUIA_COMPLETO.md` ou `DEPLOY_PRODUCTION.md`
- **THEN** a versão destacada coincide com `board_config.h`

### Requirement: Marcação física documentada como laser apenas
`README.md`, `docs/PRODUCAO.md` e `sirene_app/README.md` SHALL descrever somente gravação laser Diatu/DiatuCAD e SHALL incluir (ou apontar para) glossário Diaotu vs DiatuCAD.

#### Scenario: Onboarding posto
- **WHEN** o operador segue o checklist de produção
- **THEN** encontra passos laser e glossário Diaotu/DiatuCAD, e não é instruído a instalar driver Zebra como fluxo padrão

### Requirement: Heartbeat documentado em 10 s
Documentação de telemetria MQTT SHALL indicar intervalo de heartbeat de 10 segundos.

#### Scenario: Tabela de tópicos
- **WHEN** o guia lista `.../heartbeat`
- **THEN** o intervalo descrito é 10 s

### Requirement: OTA e USB documentados pelo app
`docs/PRODUCAO.md` (e referências no guia) SHALL descrever OTA via tela Firmware do app e flash USB pelo app (Windows) como caminhos padrão; `python -m http.server` / `idf.py flash` permanecem como fallback/recovery.

#### Scenario: Checklist produção
- **WHEN** o supervisor abre a seção OTA/atualização em PRODUCAO
- **THEN** encontra passos do app antes de comandos manuais de terminal
