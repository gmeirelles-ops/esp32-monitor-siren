## Why

O repositório não tem README na raiz nem `.gitignore`, dificultando onboarding e arriscando commit acidental de `build/`, `.dart_tool/` e `node_modules`. O único guia operacional é `docs/PRODUCAO.md`, sem mapa do monorepo.

## What Changes

- `README.md` na raiz: visão geral, estrutura (`sirene-validator`, `sirene_app`, `openspec`, `firebase`), links para `docs/PRODUCAO.md`, como rodar testes.
- `.gitignore` abrangente: Flutter, ESP-IDF build, Node, IDE, OS.
- Seção "Arquitetura" breve com diagrama ASCII.
- Mapa de capabilities OpenSpec → componentes.

## Capabilities

### New Capabilities

- `project-documentation`: documentação de repositório e onboarding

### Modified Capabilities

_(nenhuma)_

## Impact

- **Novos arquivos**: `README.md`, `.gitignore`
- **Possível**: remover artefatos já trackeados por engano (se houver) em change separada ou nota no README
