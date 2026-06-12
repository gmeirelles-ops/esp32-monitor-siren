## 1. Persistência de falhas de hardware

- [x] 1.1 Tabela `HardwareEvents` (deviceId, falha, createdAt) no Drift
- [x] 1.2 Migração schema v5 → v6 (createTable) + regen build_runner
- [x] 1.3 `insertHardwareEvent` no banco
- [x] 1.4 Persistir falha em `mqtt_providers._handleMessage` (alerta com falha)

## 2. Agregações

- [x] 2.1 `productionSummary({since})` → total/aprovados/reprovados/yield
- [x] 2.2 `throughputByDay({days})` → (dia, total, aprovados)
- [x] 2.3 `hardwareFaultCounts({since})` → (falha, count) desc

## 3. UI

- [x] 3.1 Widget `_BarChart` reutilizável (sem dependência externa)
- [x] 3.2 `DashboardScreen` com seletor de período, cartões e gráficos
- [x] 3.3 Entrada "Painel" na navegação (`app.dart`)
- [x] 3.4 Estado vazio quando não há dados no período

## 4. Testes e validação

- [x] 4.1 Teste unitário: `productionSummary` (yield, contagens, filtro de período)
- [x] 4.2 Teste unitário: `throughputByDay` agrupa por dia
- [x] 4.3 Teste unitário: `hardwareFaultCounts` agrupa e ordena
- [x] 4.4 `flutter analyze` e `flutter test` passando
