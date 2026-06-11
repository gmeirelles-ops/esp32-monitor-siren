## Why

Quatro lacunas operacionais agrupadas (todas app-side, sem firmware):

1. **OTA um a um.** Atualizar uma frota de bancadas exige repetir o OTA dispositivo por dispositivo. Falta uma campanha que envie a mesma URL de firmware para vários dispositivos de uma vez.
2. **Sem histórico de calibração.** O produto guarda só a última calibração (`calibrado_em`). Não há trilha de quando/como a `potencia_ref` mudou ao longo do tempo, dificultando auditoria de deriva.
3. **OP reutilizável.** Nada impede reconfigurar um lote com um `numero_op` já encerrado, o que mistura peças de OPs diferentes e quebra rastreabilidade.
4. **Alertas voláteis.** Falhas de hardware aparecem e somem; o supervisor não tem um feed de alertas recentes para agir.

## What Changes

- **Campanha de OTA:** seleção de múltiplos dispositivos no Admin e envio de `OTA_UPDATE` para todos, com acompanhamento por dispositivo.
- **Histórico de calibração:** registrar cada calibração (produto, potência de referência, dispositivo, instante) e exibir o histórico no formulário do produto.
- **Trava de OP:** marcar uma OP como encerrada ao `END_BATCH` e bloquear novo `SET_BATCH` com a mesma OP.
- **Alertas in-app:** feed de alertas de hardware recentes no Painel. (Push real via FCM fica fora de escopo por limitação de plataforma desktop; documentado.)

## Capabilities

### New Capabilities

- `ota-campaign`: Envio de OTA para múltiplos dispositivos a partir do app.
- `calibration-history`: Trilha histórica de calibrações por produto.
- `op-lock`: Bloqueio de reutilização de OP encerrada.

### Modified Capabilities

- `production-dashboard`: Adiciona feed de alertas de hardware recentes.

## Impact

- **App Flutter** (`sirene_app/`):
  - Banco: tabelas `CalibrationHistory` e `OpLocks` (schema v7, migração), métodos.
  - MQTT/notifier: `sendOtaCampaign`, `lockOp` no `END_BATCH`, checagem de OP no `SET_BATCH`.
  - UI: multi-seleção no `admin_screen.dart`, histórico no `product_form_screen.dart`, bloqueio/mensagem no `batch_screen.dart`, feed de alertas no `dashboard_screen.dart`.
- **Firmware ESP32**: nenhuma alteração (OTA campaign reusa `OTA_UPDATE` existente por dispositivo).
- **Firestore**: nenhuma alteração obrigatória.
