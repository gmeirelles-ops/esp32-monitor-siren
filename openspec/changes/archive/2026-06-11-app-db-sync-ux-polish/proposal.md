## Why

O app Flutter já cobre produção, sync Firestore e painel analítico, mas quatro lacunas ainda afetam o dia a dia no posto: reconciliação de seriais ignora aprovados com veredito em caixa diferente de `APROVADO`; telas de Etiquetas e Painel usam `FutureBuilder` que não reagem a novos testes; falhas permanentes da `SyncQueue` só aparecem como contador sem retry nem detalhe; e o badge de conexão MQTT fica visível apenas em Dispositivos. Esta change corrige bugs reais e polimento operacional sem novas features de negócio.

## What Changes

- Corrigir `reconcileSerials` para tratar veredito de forma case-insensitive (alinhado a `productionSummary`).
- Substituir `FutureBuilder` estático por streams/providers reativos no Painel e na tela de Etiquetas (buffer + contador).
- Adicionar UI de dead-letter da fila Firestore: listar entradas com `attempts >= 5`, exibir `last_error` e ação "Tentar novamente" (reset de attempts + reprocessamento).
- Adicionar índices SQLite em colunas de consulta frequente (`test_results.serial`, `test_results.created_at`, `sync_queue.attempts`).
- Exibir `ConnectionStatusBadge` na AppBar global (todas as telas), não só em Dispositivos.
- Testes unitários para veredito case-insensitive na reconciliação e para reset de dead-letter.

## Capabilities

### New Capabilities

_(nenhuma — melhorias em specs existentes)_

### Modified Capabilities

- `serial-counter`: reconciliação case-insensitive de veredito aprovado
- `firestore-sync`: UI de dead-letter com retry manual
- `production-dashboard`: painel reativo a novos testes sem recarregar manualmente
- `label-printing`: buffer de etiquetas reativo
- `flutter-app-shell`: badge de conexão MQTT visível em toda a navegação

## Impact

- **App Flutter**: `database.dart` (schema v8, índices, queries, `resetSyncItem`), `labels_screen.dart`, `dashboard_screen.dart`, `settings_screen.dart`, `app.dart` / `diponto_app_bar.dart`, novos providers
- **Testes**: `serial_counter_test.dart`, novo `sync_dead_letter_test.dart`
- **Firmware / Firestore rules**: sem alteração de contrato
- **Performance**: índices reduzem scans em busca de serial e agregações por data
