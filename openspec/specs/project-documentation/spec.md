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

