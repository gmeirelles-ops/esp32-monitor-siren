## Why

O app coleta resultados de teste, mas não dá ao supervisor uma visão consolidada da produção. Hoje, para saber rendimento (yield), volume testado e onde estão as falhas, alguém teria que ler o banco manualmente. Falta um painel in-app com os números do dia/semana — reaproveitando o SQLite que já temos, sem depender da nuvem.

Além disso, as falhas de hardware (`alerta`) hoje só existem em memória; somem ao reiniciar o app, impossibilitando qualquer tendência.

## What Changes

- Persistir eventos de falha de hardware (`HardwareEvents`) recebidos via MQTT.
- Adicionar consultas de agregação no SQLite: resumo de produção (total/aprovados/reprovados/yield), throughput por dia (últimos 7 dias) e contagem de falhas de hardware por tipo/dispositivo.
- Nova tela "Painel" com cartões de métricas e gráficos de barras simples (sem dependência externa), filtrável por período (hoje / 7 dias / tudo).

## Capabilities

### New Capabilities

- `production-dashboard`: Persistência de falhas de hardware e métricas/painel de produção a partir do SQLite local.

## Impact

- **App Flutter** (`sirene_app/`):
  - Banco: tabela `HardwareEvents` (schema v6, migração), métodos de agregação.
  - MQTT: persistir falha em `_handleMessage` ao receber `alerta` com `falha`.
  - UI: `dashboard_screen.dart` + entrada "Painel" na navegação (`app.dart`); widget de barras reutilizável.
- **Firmware ESP32**: nenhuma alteração.
- **Firestore**: nenhuma alteração (painel lê SQLite local).
