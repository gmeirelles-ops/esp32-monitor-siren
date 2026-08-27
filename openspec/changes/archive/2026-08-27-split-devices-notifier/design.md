## Context

Arquivo atual: `sirene_app/lib/features/mqtt/mqtt_providers.dart` (~1120 LOC). Já há parsers/modelos separados (`mqtt_parser`, `mqtt_messages`, `message_pump`). O notifier ainda faz tudo depois do parse.

## Goals / Non-Goals

**Goals**

- Reduzir complexidade cognitiva: cada arquivo < ~400 LOC preferencialmente.
- Preservar API Riverpod usada pelas telas.
- `flutter test` verde sem reescrever testes em massa.

**Non-Goals**

- Mudar protocolo MQTT ou payloads.
- Introduzir Bloc/outro state management.
- Refator “perfeita” de domínio completo (DDD).
- Extrair demo simulator para outro pacote (pode ficar no mesmo módulo de lote).

## Decisions

1. **Estratégia** — `part`/`part of` **ou** classes helper injetadas no notifier (preferir **helpers + facade** para testabilidade; evitar `part` se dificultar imports de teste).
2. **Fatias**
   - `device_mqtt_handlers.dart` — `_handleMessage`, heartbeat reconcile, watchdog, rejeições
   - `device_batch_commands.dart` — set/end batch, auto-end, reteste
   - `device_test_pipeline.dart` — `processTestResult`, serial, `_enqueueMarking`
   - `device_aux_commands.dart` — calibração, ensaio, OTA, wifi reset
3. **Providers/streams** no final de `mqtt_providers.dart` (ou `mqtt_streams.dart`) permanecem estáveis.
4. **Marking** — chamar `MarkQueueProcessor` via helper dedicado, não misturar Zebra (já removido).

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Regressão sutil em ordem de side-effects | Diff mecânico + suite completa |
| Circular imports | Helpers recebem `DevicesNotifier`/`Ref`/`AppDatabase` por parâmetro |

## Migration Plan

1. Extrair uma fatia por PR lógica (nesta change: todas as fatias em sequência).
2. Rodar `flutter test` após cada fatia.
3. Sem bump de schema Drift.

## Open Questions

- _(nenhuma)_ — helpers + facade.
