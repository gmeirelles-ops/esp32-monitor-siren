## Context

O app Flutter recebe heartbeats, presença LWT e alertas, mas:
- `lastHardwareAlert` nunca é limpo após recuperação do PZEM
- Dispositivo fica "online" se LWT não dispara mas heartbeat para
- Rejeições MQTT são parseadas mas o handler em `DevicesNotifier` é vazio (`listen((_) {})`)
- Spec `mqtt-client` já exige feedback de rejeição — gap de implementação

No firmware, `hardware_monitor_task` não registra no TWDT (inconsistência com `telemetry`/`offline_sync`, já corrigidos parcialmente).

## Goals / Non-Goals

**Goals:**
- Operador vê rejeições de comando imediatamente
- Dashboard reflete offline real (LWT + stale heartbeat)
- Alertas de hardware limpos após recuperação
- Firmware publica evento de recuperação
- `hw_mon` no TWDT

**Non-Goals:**
- Dashboard Grafana / observabilidade externa
- Histórico persistente de rejeições no SQLite
- Push notifications
- Alterar FSM ou contratos de lote

## Decisions

### 1. Stale heartbeat timeout

**Decisão:** Timer no app — se `lastSeen` > 90 s sem `heartbeat` ou `presenca`, marcar `isOnline = false`. Intervalo configurável via constante `kStaleDeviceTimeout`.

**Alternativa rejeitada:** Depender só de LWT — falha em quedas parciais de rede.

### 2. Limpeza de alerta de hardware

**Decisão:** Dupla estratégia:
1. App limpa `lastHardwareAlert` quando heartbeat reporta FSM ≠ `HARDWARE_FAULT`
2. Firmware publica `{"tipo":"hardware","evento":"recuperado"}` em `alerta` ao sair de `HARDWARE_FAULT`

### 3. Feedback de rejeição

**Decisão:** `RejectionNotifier` ou extensão de `DevicesNotifier`:
- Snackbar global via `rejectionStreamProvider` (já existe parcialmente)
- Última rejeição visível em `DeviceDetailScreen` e badge na tela de lote

### 4. TWDT em hw_mon

**Decisão:** `esp_task_wdt_add` no início de `hardware_monitor_task`; reset a cada iteração do loop (2 s).

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Falso offline com heartbeat lento | 90 s > 2× intervalo de 30 s |
| Alerta limpo cedo demais | Só limpar com FSM confirmado ou mensagem `recuperado` |
| Snackbar excessivo | Debounce de 3 s para mesma rejeição |

## Migration Plan

1. Deploy firmware 1.3.0 (ou patch 1.2.1 se separado) com alerta de recuperação
2. Deploy app — compatível com firmware antigo (limpeza por FSM funciona sem mensagem nova)
3. Validar: SET_BATCH durante TESTING → snackbar; PZEM falha → recupera → alerta some

## Open Questions

- Persistir rejeições no SQLite para auditoria? (fora de escopo v1)
- Timeout de 90 s adequado para a linha? (ajustável em Configurações futuramente)
