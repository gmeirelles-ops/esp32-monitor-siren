# Implementation Plan: 006-batch-duplicate-sequence

**Branch**: `006-batch-duplicate-sequence`  
**Spec**: [spec.md](./spec.md)

## Summary

Corrigir reteste duplicado, perda de sequência e vazamento de estado entre lotes — firmware + app.

## Phases

| Fase | Entregas |
|------|----------|
| 0 Research | [research.md](./research.md) |
| 1 Design | [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md) |
| 2 Firmware | SET_BATCH reset, cooldown pós-aprovação |
| 2 App | Dedupe, watchdog, reconciliação, UI offline/próximo seq |
| 3 Validação | Testes + bancada ([quickstart.md](./quickstart.md)) |

Ver plano detalhado em `.cursor/plans/` (gerado por `/speckit-plan`).
