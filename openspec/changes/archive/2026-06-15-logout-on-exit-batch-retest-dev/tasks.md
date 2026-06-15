## 1. Sessão de operador ao fechar o app

- [x] 1.1 Adicionar `clearActiveOperatorId()` em `AppConfig` (sem depender de `WidgetRef`)
- [x] 1.2 Registrar `WidgetsBindingObserver` no widget raiz; limpar sessão em `detached` / encerramento de janela
- [x] 1.3 Atualizar testes de `operators_test.dart` e `operator_login_screen_test.dart` para refletir sessão não persistente entre processos
- [x] 1.4 Remover ou ajustar cenários que assumem reabertura com sessão válida

## 2. Firmware — modo reteste

- [x] 2.1 Estender struct de lote em `main.c` com `modo_reteste` (NVS incluída)
- [x] 2.2 Parsear `modo_reteste` em `SET_BATCH`; preservar em retomada de lote
- [x] 2.3 Em aprovação com `modo_reteste`: não incrementar `aprovados`/`proximo_sequencial`; não disparar `cota_atingida`
- [x] 2.4 Testes unitários ou harness de lote puro cobrindo reteste (se existir suite no validator)

## 3. MQTT e app — sincronização reteste

- [x] 3.1 Criar `retestModeProvider` e incluir `modo_reteste` no payload `SET_BATCH` (`mqtt_providers.dart` / batch setup)
- [x] 3.2 Checkbox "Reteste" em `batch_live_screen.dart` com desabilitação durante `TESTING` e banner visual
- [x] 3.3 Reenviar `SET_BATCH` ao alternar checkbox (mesmos parâmetros do lote ativo)

## 4. Processamento de teste e métricas

- [x] 4.1 Migração Drift: coluna `is_retest` em `test_results` (default false)
- [x] 4.2 `processTestResult`: pular serial, buffer, `bumpSerialCounter` e `_advanceBatchSequencial` quando reteste ativo
- [x] 4.3 `getBatchMetrics` e queries do dashboard: excluir `is_retest = true` dos contadores de progresso
- [x] 4.4 `simulateTestResult`: honrar modo reteste no payload e processamento
- [x] 4.5 Testes: `batch_sequential_serials_test.dart`, novo teste de reteste sem serial/cota

## 5. Encerramento automático do lote

- [x] 5.1 Após `processTestResult`, se `aprovados_no_lote >= quantidade_total > 0`, flush órfãs e publicar `END_BATCH` (guard anti-duplicação)
- [x] 5.2 Limpar `activeBatch`, navegar ou exibir estado "lote encerrado automaticamente"
- [x] 5.3 Teste unitário/widget para auto END_BATCH quando meta atingida

## 6. Export ZPL em desenvolvimento

- [x] 6.1 Adicionar dependência de salvar arquivo se necessário (`file_selector` ou API desktop existente)
- [x] 6.2 Botão "Baixar arquivo de impressão" em `labels_screen.dart` (ou seção dev) visível só em `kDebugMode`
- [x] 6.3 Gerar ZPL do buffer via `generateZplLabelRow`; diálogo salvar com nome `etiquetas_<OP>_<timestamp>.zpl`
- [x] 6.4 Teste: botão ausente fora de debug; exportação não esvazia buffer

## 7. Validação final

- [x] 7.1 `flutter test` no pacote `sirene_app`
- [ ] 7.2 Smoke manual: login → lote → reteste → produção → meta → auto END_BATCH → fechar app → login novamente
