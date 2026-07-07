# Implementation Plan: Auditoria de Compatibilidade Firmware × Software

**Branch**: `001-fw-sw-compat` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Verificar correspondência entre firmware ESP32 (`sirene-validator` 1.7.5) e app Flutter (`sirene_app`) para evitar incompatibilidades que impeçam validação ou aprovação de produto.

## Summary

Auditoria cruzada de tópicos MQTT, schemas JSON, lógica de aprovação e fluxo pós-teste. **Conclusão principal**: o contrato operacional está **alinhado** para produção normal (SET_BATCH → teste físico → APROVADO → serial). Existem **gaps pontuais** que podem causar perda de aprovação (JSON colado — fix local pendente de commit) e falhas silenciosas (alertas NVS, ACK de batch).

## Technical Context

**Language/Version**: C (ESP-IDF firmware 1.7.5), Dart/Flutter 3.x (app desktop)

**Primary Dependencies**: ESP-IDF MQTT client, mqtt_client (Dart), PZEM-004T, Firestore sync

**Storage**: Firmware NVS (batch); App SQLite (Drift) + Firestore

**Testing**: `flutter test` (parser MQTT), `host_tests` (pure_logic firmware), E2E manual com broker

**Target Platform**: ESP32 bancada + Windows desktop app

**Project Type**: IoT produção — firmware embarcado + companion desktop

**Constraints**: MQTT 3.1.1; sem `protocol_version`; teste físico só por botão (sem START_TEST remoto)

**Scale/Scope**: 1–99 bancadas por site; contrato ~15 tipos de mensagem JSON

## Constitution Check

*GATE: Constitution template não ratificado (placeholders). Sem violações formais.*

| Princípio | Status |
|-----------|--------|
| Testes de contrato MQTT | Parcial — parser testado; batch ACK não |
| Integração firmware↔app | Auditada neste plano |
| Observabilidade | Gap em alertas NVS |

**Re-check pós-design**: Gaps documentados em `research.md`; correções recomendadas em tasks futuras.

## Project Structure

### Documentation (this feature)

```text
specs/001-fw-sw-compat/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── mqtt-commands.md
│   └── mqtt-status.md
└── tasks.md          # (/speckit-tasks)
```

### Source Code (auditado)

```text
sirene-validator/          # Firmware ESP32
├── components/mqtt_topics/
├── components/mqtt_bridge/
├── components/pure_logic/
├── main/batch_cmd.c
└── main/mqtt_cmd.c

sirene_app/                # App Flutter
├── lib/features/mqtt/
├── lib/features/batch/
└── test/mqtt_*_test.dart
```

**Structure Decision**: Monorepo com firmware e app separados; contrato MQTT é a interface de integração.

## Findings — Matriz de Compatibilidade

### ✅ Alinhado (sem risco de produção)

| Área | Detalhe |
|------|---------|
| Tópicos | `{site}/bancada-NN/{suffix}` em ambos |
| SET_BATCH | 10 campos idênticos + validação equivalente |
| Veredito | `APROVADO`/`REPROVADO`; limites inclusivos no firmware |
| Sequencial | Firmware publica; app gera serial ITF |
| Modo reteste | Contadores e serial suprimidos em ambos |
| FSM estados | 6 estados coincidem |
| Calibração / Ensaio | Contratos compatíveis |
| Rejeições | 30+ códigos publicados; app parseia `rejeicao` |

### ⚠️ Gaps com impacto em produção

| # | Gap | Impacto | Status |
|---|-----|---------|--------|
| G1 | **JSON colado no `/status`** | Aprovação no firmware sem registro no app | ✅ Corrigido |
| G2 | **`batch_nvs_fault` não parseado** | Falha NVS invisível | ✅ Corrigido |
| G3 | **ACK `tipo:batch` ignorado** | SET_BATCH sem confirmação | ✅ Corrigido |
| G4 | **Duplo END_BATCH na cota** | Possível race firmware+app | ✅ Mitigado |
| G5 | **OpenSpec desatualizada** | Doc legada | ✅ Atualizado |

### ℹ️ Diferenças aceitáveis

- App não revalida potência (confia no firmware) — by design
- Heartbeat extras ignorados pelo app
- Ensaio: app mais restritivo (múltiplos de 60s)
- Sem `protocol_version` — risco em upgrades futuros

## Complexity Tracking

N/A — auditoria read-only; correções são incrementais.

## Recommended Next Steps

1. **P0**: Commitar e validar fix de parser MQTT colado (`mqtt_parser.dart`, testes).
2. **P1**: Implementar parse de `batch_nvs_fault` e `tipo:batch` ACK.
3. **P2**: Atualizar OpenSpec `mqtt-messaging` para esquema `bancada-NN`.
4. **P2**: Rodar quickstart E2E em bancada real antes de release.

## Generated Artifacts

| Artefato | Caminho |
|----------|---------|
| Spec | `specs/001-fw-sw-compat/spec.md` |
| Research | `specs/001-fw-sw-compat/research.md` |
| Data model | `specs/001-fw-sw-compat/data-model.md` |
| Contracts | `specs/001-fw-sw-compat/contracts/` |
| Quickstart | `specs/001-fw-sw-compat/quickstart.md` |
