## Why

O **Painel** atual no app do operador já calcula métricas ricas (KPIs, gráficos, produção por lote), mas o mock de referência é claramente voltado ao **gestor/supervisor** — com comparativos (% vs ontem/média), tabela de lotes com status e layout analítico. Misturar isso com o fluxo do chão de fábrica polui a UX do operador.

No app operador, o botão **"Configurar lote"** não reflete a ação real (iniciar produção). O badge **"Desconectado"** aparece incorretamente no topo mesmo com MQTT e bancadas funcionando — provável estado inicial do `StreamProvider` antes do primeiro evento.

## What Changes

### App operador (`sirene_app`) — ajustes rápidos

- Renomear botão principal do lote: **"Configurar lote (SET_BATCH)"** → **"INICIAR"**
- Corrigir badge MQTT na AppBar: não exibir **"Desconectado"** enquanto conexão está em `connecting`/`connected` ou antes do primeiro evento do stream (usar `MqttService.currentState`)
- **Enxugar o Painel** do operador: resumo mínimo do turno (testes hoje, lote ativo) **ou** remover item "Painel" da navegação — métricas analíticas migram para o app gestor

### Novo app gestor (`sirene_manager_app`)

- App Flutter desktop separado, tema Diponto, conectado à **nuvem (Firestore)** — mesma hierarquia `test_results` / `lotes` já sincronizada pelos postos
- Dashboard conforme mock:
  - Filtros: Hoje / 7 dias / Tudo + OP, Produto, Bancada
  - Cards: Testado, Rendimento, Reprovados, Falhas HW (com variação vs ontem/média quando dados existirem)
  - Gráfico barras empilhadas: Testado vs Aprovados (7 dias)
  - Gráfico linha/área: Rendimento % diário + linha de meta (ex. 70%)
  - Tabela **Produção por lote** (OP, testes, aprovados, reprovados, rendimento, status) **sem coluna Ações**
- Login Firebase (gestor); leitura multi-posto via `station_id` ou visão consolidada da fábrica
- Sem MQTT nem controle de bancada — somente leitura analítica

### Sugestões incluídas

| Sugestão | Escopo |
|----------|--------|
| Barra de busca global no gestor | Fase 2 — busca por OP/serial |
| Export CSV/PDF do painel gestor | Fase 2 |
| Painel operador vira link "Abrir analytics" só se gestor instalado | Fora de escopo v1 |

### Fora de escopo

- Alterar firmware ou protocolo MQTT
- Escrever dados no Firestore a partir do app gestor
- Substituir Relatório de rastreabilidade do operador

## Capabilities

### New Capabilities

- `manager-analytics-app`: app gestor desktop com dashboard analítico Firestore
- `firestore-analytics-queries`: agregações e filtros para KPIs, gráficos e tabela por lote

### Modified Capabilities

- `batch-operator-ui`: botão INICIAR no fluxo de lote
- `flutter-app-shell`: correção do badge MQTT; navegação sem painel analítico completo
- `production-dashboard`: escopo movido para app gestor; operador mantém visão mínima ou nenhuma

## Impact

- `sirene_app/lib/features/batch/batch_screen.dart` — rótulo INICIAR
- `sirene_app/lib/shared/widgets/connection_status.dart` — estado inicial MQTT
- `sirene_app/lib/app.dart` — navegação (Painel enxuto ou removido)
- Novo pacote `sirene_manager_app/` — projeto Flutter
- `firebase/firestore.rules` — leitura para role gestor (se necessário)
- Queries Firestore / Cloud Functions opcionais para agregações pesadas
