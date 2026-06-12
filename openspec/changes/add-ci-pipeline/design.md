## Context

Testes existentes:
- `sirene_app`: `flutter test` (55 testes, Drift in-memory)
- `sirene-validator/host_tests`: CMake + CTest sobre `pure_logic`

Não há `.github/workflows/` no repositório. O build Flutter Windows não roda em runner Linux (esperado). ESP-IDF exige setup pesado (~2 GB).

## Goals / Non-Goals

**Goals:**
- Feedback rápido em PR (< 10 min) com testes Dart e C host.
- Reproduzir comandos localmente com um script único.

**Non-Goals:**
- Build release Windows no CI.
- Flash/hardware-in-the-loop.
- Deploy automático Firebase ou OTA.

## Decisions

### 1. Runner Ubuntu + Flutter stable

**Decisão:** `ubuntu-latest`, cache de `pub` e `.dart_tool`, `flutter test` em `sirene_app`.

**Alternativa:** self-hosted runner no posto — latência e manutenção maiores.

### 2. Host tests via CMake

**Decisão:** job `firmware-host-tests` executa:
```bash
cd sirene-validator/host_tests && cmake -B build && cmake --build build && ctest --test-dir build --output-on-failure
```

### 3. IDF build opcional

**Decisão:** job `firmware-idf-build` com `continue-on-error: true` ou `workflow_dispatch` até ESP-IDF estar cacheado de forma confiável. Documentar no README.

### 4. Triggers

**Decisão:** `push` e `pull_request` em `main`; paths-ignore para `docs/` e `openspec/changes/archive/` se necessário.

## Risks / Trade-offs

- **[IDF lento ou instável no GH Actions]** → job separado, não bloqueante na v1.
- **[Flutter version drift]** → pin `flutter-version` no workflow.
- **[Drift codegen]** → `dart run build_runner build --delete-conflicting-outputs` antes dos testes se arquivos `.g.dart` faltarem.

## Migration Plan

1. Adicionar workflow e validar no primeiro PR.
2. Habilitar branch protection exigindo CI verde.
3. Comunicar ao time o comando local espelho: `./scripts/ci_local.sh`.

## Open Questions

- Pin exato da versão Flutter (usar a do `pubspec.yaml` / FVM se adotado depois).
