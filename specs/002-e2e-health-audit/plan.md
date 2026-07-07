# Implementation Plan: Auditoria ponta a ponta — Diponto Sirene

**Branch**: `002-e2e-health-audit` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Verificar se todo o projeto Diponto Sirene funciona de ponta a ponta (firmware 1.7.5, app Windows, MQTT, serial/etiqueta/laser, Firestore, operador).

## Summary

Auditoria E2E em 6 fases (pré-requisitos → MQTT → teste físico → serial → cloud → CI). Núcleo técnico alinhado após `001-fw-sw-compat`; bloqueadores restantes: deploy app corrigido, validação física na bancada, e alinhamento de docs/scripts.

## Technical Context

**Language/Version**: C (ESP-IDF 5.x, firmware 1.7.5), Dart/Flutter 3.x (sirene_app Windows)

**Primary Dependencies**: Mosquitto MQTT, PZEM-004T, Drift/SQLite, Firebase Firestore, Zebra ZPL / Diatu TCP laser

**Storage**: Firmware NVS + SPIFFS queue; App SQLite + SyncQueue; Cloud Firestore

**Testing**: `flutter test` (52 files), firmware `host_tests`, `ci_local.sh`; E2E físico manual

**Target Platform**: ESP32 bancada + Windows posto

**Project Type**: IoT factory validation monorepo

**Constraints**: Teste físico só por botão; sync cloud Windows-only; dist requer confirmação explícita

## Constitution Check

Template constitution não ratificado — sem gates formais. Princípios aplicados: testes automatizados + checklist físico antes de release produção.

## Project Structure

```text
specs/002-e2e-health-audit/
├── spec.md
├── plan.md
├── research.md
├── quickstart.md
├── tasks.md
├── bench-results.md
└── checklists/requirements.md

sirene-validator/     # Firmware ESP32 v1.7.5
sirene_app/           # App operador/gestor Windows
firebase/             # Firestore rules
scripts/              # ci_local, e2e, build
docs/PRODUCAO.md      # Checklist fábrica
```

## Findings Summary

| Camada | Status |
|--------|--------|
| Firmware ↔ App MQTT | OK |
| App parser/dedupe | OK (código local) |
| CI automatizado | OK |
| E2E físico | PENDENTE |
| Docs/scripts E2E | Corrigido nesta feature |
| Firestore sync | OK (spec + código) |

## Generated Artifacts

| Artefato | Path |
|----------|------|
| Spec | `specs/002-e2e-health-audit/spec.md` |
| Research | `specs/002-e2e-health-audit/research.md` |
| Quickstart | `specs/002-e2e-health-audit/quickstart.md` |
| Bench results | `specs/002-e2e-health-audit/bench-results.md` |
| Tasks | `specs/002-e2e-health-audit/tasks.md` |

## Recommended Execution Order

1. Corrigir doc drift (PRODUCAO, e2e script, README)
2. Commit correções MQTT app
3. Deploy app no posto (dist com confirmação)
4. Executar quickstart §A–F na bancada real
5. Registrar resultados em bench-results.md
