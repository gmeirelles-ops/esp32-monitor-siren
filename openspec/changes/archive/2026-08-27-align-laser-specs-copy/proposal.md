## Why

A change `docs-align-laser-only` removeu Zebra do runtime, mas **specs OpenSpec ativas** e **copy residual na UI** ainda falam em buffer de etiquetas, reimpressão ZPL e impressora Zebra. Isso induz erro em onboarding e em futuras implementações. Além disso, **Diaotu** (marca do laser B3) vs **Diatu/DiatuCAD** (software/protocolo no app) precisa ficar documentado como nomenclatura intencional — não como typo.

## What Changes

- Atualizar requirements em specs ativas que ainda assumem Zebra/buffer ZPL para o fluxo laser (`mark_queue` + Regravar).
- Marcar / aposentar capability `dev-label-file-export` (ZPL debug) se código já não expõe download ZPL.
- Corrigir copy operador: Consulta, bootstrap Firebase, comentários/testes que dizem “etiqueta” no sentido de marcação física.
- Documentar glossário curto: **Diaotu** = hardware; **DiatuCAD** = software de gravação; app usa Diatu* nas APIs.
- Sem mudança de protocolo MQTT/firmware.

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `serial-and-labels`, `serial-traceability`, `siren-traceability-report`
- `batch-live-dashboard`, `batch-test-execution`, `batch-retest-mode`
- `mqtt-client`, `operator-traceability`, `serial-counter`
- `device-monitoring`, `flutter-app-shell`, `desktop-ui-layout`
- `diatu-laser-marking`, `project-documentation`
- `dev-label-file-export` (RETIRED se aplicável)

## Impact

- **Docs/OpenSpec** + poucas strings/comentários no `sirene_app`
- Runtime de marcação inalterado
- Archives históricos preservados
