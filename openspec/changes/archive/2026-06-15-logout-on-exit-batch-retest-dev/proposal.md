## Why

Após o login por PIN, a sessão do operador persiste entre reinicializações do app, permitindo que outra pessoa use o posto sem autenticar. No fluxo de lote, o operador precisa encerrar manualmente quando a meta é atingida, não há forma de repetir um teste sem consumir serial e cota, e desenvolvedores não conseguem inspecionar o arquivo ZPL de impressão sem enviar à impressora.

## What Changes

- **BREAKING**: Ao fechar ou encerrar o processo do app, a sessão do operador é limpa; na próxima abertura o login por PIN é obrigatório novamente.
- O app envia `END_BATCH` automaticamente quando o lote atinge a meta (`aprovados >= quantidade_total` com `quantidade_total > 0`), encerrando o lote sem ação manual do operador.
- Checkbox **Reteste** no Batch Live Dashboard: com a caixa marcada, o ciclo de teste roda normalmente (leitura MQTT, veredito, UI), mas **não** gera serial, **não** incrementa contador de serial, **não** adiciona ao buffer de etiquetas e **não** consome cota do lote (aprovados/sequencial no firmware e métricas de progresso no app).
- Ação **Baixar arquivo de impressão** (ZPL) visível somente em builds de desenvolvimento (`kDebugMode`), para salvar o conteúdo que seria enviado à impressora sem imprimir.

## Capabilities

### New Capabilities

- `batch-retest-mode`: modo reteste coordenado entre app e firmware — checkbox na UI, flag MQTT e exclusão de serial/cota
- `dev-label-file-export`: exportação de arquivo ZPL para disco apenas em modo desenvolvimento

### Modified Capabilities

- `operator-pin-login`: sessão de operador limitada à execução corrente do app (sem persistência entre fechamentos)
- `batch-live-dashboard`: encerramento automático do lote ao atingir a meta; checkbox de reteste na tela
- `batch-test-execution`: firmware respeita modo reteste sem incrementar `aprovados` nem `proximo_sequencial`
- `mqtt-messaging`: contrato MQTT estendido com flag `modo_reteste` em `SET_BATCH` (ou comando dedicado)
- `serial-and-labels`: geração de serial e buffer de etiquetas ignorados em reteste
- `label-printing`: download de arquivo ZPL restrito a desenvolvimento
- `batch-dev-simulator`: simulador honra modo reteste da mesma forma que testes reais

## Impact

- **App Flutter**: `app.dart` (lifecycle / `WidgetsBindingObserver`), `operators_provider.dart`, `batch_live_screen.dart`, `mqtt_providers.dart` (`processTestResult`, auto `END_BATCH`), provider de `retestMode`, tela de Etiquetas ou Batch Live (botão dev)
- **Firmware ESP32**: `main.c` — flag `modo_reteste` no lote; publicação de resultado sem consumir sequencial/cota quando ativa
- **MQTT**: campo opcional `modo_reteste` em `SET_BATCH` (boolean)
- **SQLite**: coluna opcional `is_retest` em `test_results` para distinguir retestes no relatório (recomendado)
- **Testes**: unitários para sessão ao lifecycle, reteste sem serial, auto END_BATCH, export ZPL só em debug
