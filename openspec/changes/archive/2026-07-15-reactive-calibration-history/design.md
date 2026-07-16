## Context

`CalibrationHistory` table existe. `product_form_screen.dart` linha ~375 usa `FutureBuilder<List<CalibrationHistoryData>>`.

Padrão já aplicado em Labels e Dashboard: `watch*` streams + `StreamBuilder` ou provider reativo.

## Goals / Non-Goals

**Goals:**
- Histórico atualiza ao gravar nova calibração (local ou via MQTT).

**Non-Goals:**
- Refatorar todas as outras telas com FutureBuilder.

## Decisions

### 1. watchCalibrationHistory

**Decisão:** query Drift `.watch()` filtrada por `id_produto` ordenada por data desc.

### 2. Pipeline MQTT

**Decisão:** ao parsear `calibracao` com produto conhecido, `insertCalibrationHistory` se ainda não existir + stream atualiza automaticamente.

## Risks / Trade-offs

- **[Duplicata de entrada]** → upsert por `(id_produto, device_id, timestamp)` ou ignorar se já gravado.

## Migration Plan

1. Deploy app; validar calibração ao vivo na tela de produto.

## Open Questions

- Nenhuma.
