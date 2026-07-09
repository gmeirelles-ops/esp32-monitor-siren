# Validação em bancada — spec 006

Registro de execução dos cenários do [quickstart.md](quickstart.md). Preencher em hardware real.

## Pré-requisitos de campo

- [ ] Firmware **≥ 1.8.6** gravado na bancada (`board_config.h` / heartbeat)
- [ ] App Flutter atualizado (Sprint A: `sendEndBatch`, `encerrado`, serial duplicado)
- [ ] Broker MQTT acessível do posto
- [ ] PZEM calibrado

## Cenários automatizados (CI)

Executados em `2026-07-09` como proxy até bancada disponível:

```bash
cd sirene_app && flutter test test/batch_integrity_sprint_a_test.dart
cd sirene-validator/host_tests && cmake -B build && cmake --build build && ctest --test-dir build
```

| Check | Comando | Resultado |
|-------|---------|-----------|
| Sprint A app tests | `flutter test test/batch_integrity_sprint_a_test.dart` | **PASS** (3/3) — 2026-07-09 |
| Host tests firmware | `ctest --test-dir build` | Pendente neste PC (cmake não no PATH); rodar em CI/Linux |
| Suite completa app | `flutter test` | **234 pass / 3 fail** (falhas pré-existentes não relacionadas) — 2026-07-09 |

## Cenários manuais (bancada real) — PENDENTE HARDWARE

> Executar na bancada quando COM/USB e broker estiverem disponíveis.
> Firmware alvo: **1.8.6** (NVS-before-GPIO + Sprint A no app).

| # | Cenário | FR | Passou? | Data | Observações |
|---|---------|-----|---------|------|-------------|
| 1 | Bloqueio reteste &lt;5 s após aprovação | FR-004 | | | |
| 2 | Novo lote mesma OP — sessão limpa | FR-006 | | | |
| 3 | MQTT instável 60 s — reconciliação | FR-007 | | | |
| 4 | Reprovações no mesmo sequencial | FR-002/003 | | | |
| 5 | Encerrar lote app com MQTT down — **deve falhar** | R02 | | | Esperado: `mqtt_desconectado`, lote permanece |
| 6 | Encerrar lote no firmware — app + Firestore | R03 | | | Esperado: OP locked, status completed |
| 7 | Gravar firmware 1.8.6 e confirmar heartbeat | — | | | `firmware=1.8.6` no heartbeat |

## Critérios de aceite (spec 006)

- **SC-001:** Zero 3+ testes na mesma peça aprovada em lote de 10
- **SC-002:** Após 5 aprovações, sequencial esperado = 6 (app + firmware)
- **SC-004:** Queda MQTT 60 s — recuperação sem recadastrar lote
- **SC-005:** Novo lote sem vazamento de contagem anterior

## Responsável

| Campo | Valor |
|-------|-------|
| Operador | |
| Bancada | |
| Firmware | |
| App build | |
