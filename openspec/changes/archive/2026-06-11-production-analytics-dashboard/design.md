## Context

`test_results` guarda `veredito`, `potenciaMedia`, `createdAt`, `deviceId`, `numeroOp`, `serial`. Falhas de hardware chegam por `alerta` (`falha`, `evento`) e só vivem em memória (`device.lastHardwareAlert`). Não há dependências de gráfico no `pubspec`.

## Goals / Non-Goals

**Goals:**

- Painel local com yield, throughput e falhas, filtrável por período.
- Persistir falhas de hardware para permitir tendência.

**Non-Goals:**

- Dashboards na nuvem / multi-posto agregado (futuro; este lê o SQLite do posto).
- Biblioteca de gráficos externa — barras simples com `Container` bastam.

## Decisions

### 1. Tabela `HardwareEvents`

```
HardwareEvents
  id        INTEGER autoincrement
  deviceId  TEXT
  falha     TEXT
  createdAt DateTime
```

Persistida em `_handleMessage` quando `alert.falha != null` (não-recuperação). Migração schema v5 → v6 (createTable).

### 2. Agregações no banco (SQL puro via Drift)

- `productionSummary({since})` → `(total, aprovados, reprovados, yield)`.
- `throughputByDay({days})` → lista `(dia, total, aprovados)` agrupada por data local.
- `hardwareFaultCounts({since})` → lista `(falha, count)` ordenada desc.

Implementadas com `customSelect`/`selectOnly` para agregar; período via filtro `createdAt >= since`.

### 3. Tela "Painel"

`DashboardScreen` (ConsumerStatefulWidget) com seletor de período (SegmentedButton: Hoje / 7 dias / Tudo), cartões de métrica (total, yield%, reprovados, falhas HW) e dois gráficos de barras (throughput/dia e falhas por tipo). Recarrega via `FutureBuilder` ao trocar período.

Gráfico = `_BarChart` reutilizável: normaliza valores e desenha barras com altura proporcional usando `Container` + `Flexible`. Sem dependências.

### 4. Navegação

Nova destination "Painel" (ícone `Icons.insights`) inserida após "Lote" em `app.dart` (`_destinations` e `_screens`), válida para rail (desktop) e bottom bar (mobile).

## Risks / Trade-offs

- **[Trade-off] Métricas só do posto local** — coerente com offline-first; agregação multi-posto fica para um dashboard de nuvem futuro.
- **[Risco] Volume grande de test_results** deixa agregação lenta → mitigado por filtro de período e índice natural por `createdAt` (consultas simples, volume por posto é baixo).

## Migration Plan

1. Tabela + migração v6, regen build_runner.
2. Persistir falhas no MQTT.
3. Métodos de agregação + testes.
4. Tela + navegação + widget de barras.
5. `flutter analyze`/`test`.
