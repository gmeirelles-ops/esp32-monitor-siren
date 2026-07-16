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

