## Context

Produto interno é **laser-only**. Código: `MarkQueue` + `DiatuLaserTcpServer`. Specs em `openspec/specs/` ainda misturam linguagem de etiquetas (legado Zebra). UI: `LookupScreen` subtitle “reimprimir etiquetas”; `firebase_bootstrap` menciona etiquetas.

Hardware real: **Diaotu B3** + software **DiatuCAD** (`docs/laser-reference/`).

## Goals / Non-Goals

**Goals**

- Specs ativas descrevem só laser / `mark_queue` / Regravar.
- Copy operador alinhada (Consulta, mensagens de nuvem off).
- Glossário Diaotu vs DiatuCAD na referência laser e na capability `diatu-laser-marking`.

**Non-Goals**

- Renomear “Diaotu” → “Diatu” (é a marca do equipamento).
- Reescrever `openspec/changes/archive/**`.
- Remover mais código além do que docs-align já tirou.
- Segurança / TLS / dist Windows.

## Decisions

1. **Texto canônico pós-aprovação:** “enfileira gravação laser” / “Regravar” — nunca “buffer de etiquetas” / “reimprimir” nas specs ativas.
2. **Specs RETIRED** (`label-printing`, ZPL layout, etc.) permanecem stub; só atualizar se ainda apontarem fluxo errado.
3. **`dev-label-file-export`:** RETIRED (mesmo padrão de `label-printing`) se o app não tiver mais download ZPL.
4. **Glossário** em `docs/laser-reference/README.md`:
   - Diaotu — fabricante/modelo do laser
   - DiatuCAD — software de job/TCP
   - App — classes `Diatu*` / capability `diatu-laser-marking`

## Risks / Trade-offs

- Specs longas (batch-test-execution, mqtt-client) exigem edição cirúrgica para não quebrar requisitos MQTT válidos.
- Testes unitários com nomes “etiqueta” podem só renomear descrição, não lógica.

## Migration Plan

1. Aplicar deltas OpenSpec → `openspec/specs/`.
2. Patch strings UI + glossário.
3. `flutter test` (smoke).
4. Arquivar change.
