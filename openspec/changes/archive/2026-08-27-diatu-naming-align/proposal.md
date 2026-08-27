## Why

OpenSpec e o README ainda citavam a capability `diatom-laser-marking` / “Diatom”, enquanto o produto e o código usam **Diatu / DiatuCAD**. Alinhar o nome evita confusão em docs e onboarding.

## What Changes

- Renomear capability OpenSpec `diatom-laser-marking` → `diatu-laser-marking`.
- Atualizar referências no README e specs RETIRED (Zebra).
- Sem mudança de runtime (código já usa Diatu*).

## Capabilities

### New Capabilities

- `diatu-laser-marking` (rename da capability antiga)

### Modified Capabilities

- Specs retired que apontavam para `diatom-laser-marking`
- `project-documentation` / README capabilities table

## Impact

- Apenas docs/OpenSpec; archives históricos preservam o nome antigo.
