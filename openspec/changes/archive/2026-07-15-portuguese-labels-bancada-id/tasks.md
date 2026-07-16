## 1. Bancadas numeradas



- [x] 1.1 Criar tabela Drift `bancadas` (`numero`, `deviceId` unique, `createdAt`) e migração com backfill a partir de `test_results`

- [x] 1.2 Implementar `ensureBancada(deviceId)` e `getBancadaByDevice` / mapa em `database.dart`

- [x] 1.3 Chamar `ensureBancada` no primeiro heartbeat/presença em `DevicesNotifier`

- [x] 1.4 Atualizar `formatBancadaLabel` para resolver `Bancada N` via lookup assíncrono ou provider

- [x] 1.5 Exibir MAC como "Identificador técnico" em `device_detail_screen.dart`

- [x] 1.6 Testes unitários: primeira bancada = 1, segunda = 2, estabilidade, backfill



## 2. Nomenclatura em português



- [x] 2.1 Criar `portuguese_labels.dart` com constantes (Rendimento, Conectada, Desconectada, etc.)

- [x] 2.2 Renomear navegação "Dispositivos" → "Bancadas" em `app.dart` e `devices_screen.dart`

- [x] 2.3 Substituir Yield → Rendimento em `dashboard_screen.dart` e métricas relacionadas

- [x] 2.4 Substituir Online/Offline → Conectada/Desconectada em detalhe da bancada

- [x] 2.5 Atualizar `batch_live_screen.dart`: Total testadas, Rendimento, botão "Encerrar lote"

- [x] 2.6 Atualizar cabeçalhos CSV em `batch_report_export.dart` para português consistente

- [x] 2.7 Testes de widget ou unitários para rótulos PT nas telas alteradas



## 3. Export ZPL (verificação)



- [x] 3.1 Renomear botão para "Baixar arquivo ZPL" em `labels_screen.dart`

- [x] 3.2 Gerar ZPL concatenado com `printLabelBatches` quando buffer > 3 seriais

- [x] 3.3 Garantir filtro de tipo `.zpl` e nome `etiquetas_<OP>_<timestamp>.zpl`

- [x] 3.4 Teste: arquivo contém `^XA`/`^XZ`; buffer não é esvaziado; múltiplos blocos para 6 seriais



## 4. Integração em relatórios e filtros



- [x] 4.1 Aplicar `formatBancadaLabel` em relatório, painel e filtros (já parcial — validar com número)

- [x] 4.2 Provider `bancadasMapProvider` para listas de filtro ordenadas por número

- [x] 4.3 Testes de export CSV com coluna Bancada numerada



## 5. Validação



- [x] 5.1 `flutter test` no pacote `sirene_app`

- [x] 5.2 Smoke manual: nova bancada MQTT → Bancada 1; UI sem MAC visível; download ZPL em debug

