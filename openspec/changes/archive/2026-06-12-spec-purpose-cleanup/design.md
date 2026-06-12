## Context

Specs afetadas incluem: `production-dashboard`, `serial-counter`, `label-printing`, `flutter-app-shell`, `offline-resilience`, `batch-test-execution`, `mqtt-client`, `ota-campaign`, `op-lock`, `calibration-history`, `product-catalog`, `catalog-cloud-pull`, `operator-traceability`, `serial-traceability`, `batch-operator-ui`, `desktop-ui-layout`, `system-robustness`, `calibration-mode`, `calibration-and-ota`, `ota-update`, `device-telemetry`, `wifi-provisioning-wizard`, `serial-and-labels`.

Algumas specs já têm Purpose preenchido (`firestore-sync`, `mqtt-messaging`, `device-monitoring`, `firebase-auth`, `firebase-setup`, `hardware-monitoring`, `wifi-provisioning`).

## Goals / Non-Goals

**Goals:**
- Uma frase clara de propósito por spec, em português, alinhada ao domínio Diponto.
- Manter requirements intactos.

**Non-Goals:**
- Reescrever requirements.
- Mesclar ou dividir capabilities.

## Decisions

### 1. Edição direta nas specs principais

**Decisão:** editar `openspec/specs/<capability>/spec.md` in-place, não via delta archive — esta change é meta-manutenção aplicada diretamente.

**Alternativa:** delta specs vazios — desnecessário para texto de Purpose.

### 2. Formato do Purpose

**Decisão:** 1–2 frases: o que a capability cobre e qual componente (firmware vs app).

## Risks / Trade-offs

- **[Nenhum risco operacional]** → change só documental.

## Migration Plan

1. Aplicar textos em lote.
2. `openspec validate` se disponível.

## Open Questions

- Nenhuma.
