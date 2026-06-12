## Context

OTA hoje: `DevicesNotifier.sendOtaUpdate(deviceId, url)` publica `{cmd: OTA_UPDATE, url}` via MQTT. Produto guarda só última calibração. `sendEndBatch` encerra lote mas não trava a OP. Falhas de hardware já são persistidas em `HardwareEvents` (mudança anterior).

## Goals / Non-Goals

**Goals:** campanha OTA multi-dispositivo; trilha de calibração; trava de OP; feed de alertas in-app.

**Non-Goals:**
- Push notifications reais (FCM) no desktop — inviável de forma confiável; alertas ficam in-app.
- Orquestração de OTA pela nuvem (devices só falam MQTT; o app é a ponte).
- Cancelamento/rollback de OTA.

## Decisions

### 1. Campanha de OTA = laço sobre dispositivos

`sendOtaCampaign(List<String> deviceIds, String url)` publica `OTA_UPDATE` para cada dispositivo. UI: lista com checkboxes + botão. Status por dispositivo continua vindo do `otaStreamProvider` existente.

### 2. `CalibrationHistory`

```
CalibrationHistory
  id          INTEGER autoincrement
  idProduto   TEXT
  potenciaRef REAL
  deviceId    TEXT nullable
  createdAt   DateTime
```

`insertCalibration` é chamado no `_save` do formulário **somente quando houve nova calibração na sessão** (`_calibratedAt != null`). `getCalibrationHistory(idProduto)` retorna desc por data. Exibido no formulário quando editando.

### 3. `OpLocks`

```
OpLocks
  numeroOp  TEXT primaryKey
  status    TEXT          // 'completed'
  lockedAt  DateTime
```

`lockOp(numeroOp)` no `sendEndBatch`. `isOpLocked(numeroOp)` consultado antes do `SET_BATCH`; se travada, o app bloqueia e orienta usar nova OP. Trava é local ao posto (coerente com offline-first).

**Trade-off:** trava por posto não cobre dois postos usando a mesma OP simultaneamente — aceitável na v1; rastreabilidade multi-posto fica para evolução na nuvem.

### 4. Alertas in-app

`recentHardwareEvents(limit)` lê `HardwareEvents` desc. Card "Alertas recentes" no Painel. Sem FCM.

### 5. Migração v6 → v7

`createTable(calibrationHistory)` e `createTable(opLocks)`.

## Risks / Trade-offs

- **[Risco] Operador precisa legitimamente reabrir uma OP travada** → mensagem orienta criar nova OP; (override manual fica fora de escopo).
- **[Risco] Campanha OTA em dispositivo offline** → publish MQTT não entregue; status não chega. Mitigado: UI lista apenas dispositivos conhecidos e mostra status por dispositivo.

## Migration Plan

1. Tabelas + migração v7 + regen.
2. Métodos de banco + testes (lock, history).
3. `sendOtaCampaign`; lock no END_BATCH; checagem no SET_BATCH.
4. UI: admin multi-seleção, histórico no produto, bloqueio no lote, alertas no painel.
5. `flutter analyze`/`test`.
