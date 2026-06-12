## Context

Monorepo: firmware ESP-IDF, app Flutter Windows/Linux, Firebase rules, OpenSpec, scripts Node para Firebase CLI.

`scripts/node_modules` existe localmente; verificar se está no git (parece não estar trackeado nos primeiros arquivos do git ls-files).

## Goals / Non-Goals

**Goals:**
- Onboarding < 15 min para dev novo.
- Ignorar artefatos de build por padrão.

**Non-Goals:**
- Documentação API completa do MQTT (já em specs).
- Wiki externa.

## Decisions

### 1. README estrutura

**Decisão:** seções: O que é, Estrutura, Pré-requisitos, Testes rápidos, Produção (link), OpenSpec workflow.

### 2. .gitignore

**Decisão:** templates padrão Flutter + `sirene-validator/build/`, `managed_components/`, `.cursor` opcional (manter trackeado se o time usa), `scripts/node_modules/`.

### 3. Idioma

**Decisão:** README em português, alinhado a `PRODUCAO.md`.

## Risks / Trade-offs

- **[Arquivos build já commitados]** → não remover nesta change sem auditar; `.gitignore` só previne futuros.

## Migration Plan

1. Adicionar arquivos.
2. Revisar `git status` após primeiro clone limpo.

## Open Questions

- Badge CI no README depende de `add-ci-pipeline` — placeholder ou adicionar depois.
