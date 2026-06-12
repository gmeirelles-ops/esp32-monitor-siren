## 1. Dados e providers

- [x] 1.1 Adicionar `watchTestsByOp(numeroOp)` e `getBatchMetrics(numeroOp)` em `AppDatabase`
- [x] 1.2 Criar `batchLiveMetricsProvider` derivando aprovados, reprovados, yield e pendentes
- [x] 1.3 Criar `batchLiveTestsProvider` (stream de testes da OP) integrado a `localDataRevisionProvider`

## 2. Batch Live Dashboard (UI)

- [x] 2.1 Criar `batch_live_screen.dart` com cabeçalho (OP, produto, dispositivo, operador, FSM)
- [x] 2.2 Implementar cards de métricas e barra de progresso da meta
- [x] 2.3 Implementar gráfico de potência por teste (reutilizar padrão `_BarChart` do Painel) com faixa min/max
- [x] 2.4 Implementar lista cronológica de testes com sequencial, veredito, potência, serial e horário
- [x] 2.5 Adicionar indicadores `BATCH_READY` / `TESTING` e botão `END_BATCH` com confirmação
- [x] 2.6 Exibir banner de atalho quando etiquetas estão na fila ou última rejeição MQTT

## 3. Fluxo de navegação

- [x] 3.1 Após `sendSetBatch` bem-sucedido em `BatchScreen`, navegar para `BatchLiveScreen`
- [x] 3.2 Enxugar `BatchScreen`: remover cards de progresso/último teste (migrados ao dashboard)
- [x] 3.3 Adicionar banner "Ver lote em andamento" quando `activeBatch` existir no dispositivo selecionado
- [x] 3.4 Ao encerrar lote no dashboard, retornar à configuração com feedback

## 4. Simulador de desenvolvimento (app)

- [x] 4.1 Extrair handler de resultado de teste MQTT para método reutilizável em `DevicesNotifier`
- [x] 4.2 Implementar `simulateTestResult(deviceId)` com potência fictícia e veredito coerente
- [x] 4.3 Adicionar botão "Simular teste" visível apenas em `kDebugMode` no dashboard
- [x] 4.4 Gravar testes simulados com `operador: dev-simulator` e banner "MODO DEV"
- [x] 4.5 Teste widget/unitário do simulador e atualização das métricas

## 5. Simulador de desenvolvimento (firmware, opcional)

- [x] 5.1 Adicionar Kconfig `CONFIG_DEV_MOCK_PZEM` (default desligado)
- [x] 5.2 Implementar ramo mock em `pzem_measure_cycle` com amostras sintéticas
- [x] 5.3 Documentar uso em `docs/TESTING.md` (build com mock para bancada sem PZEM)

## 6. Testes e specs

- [x] 6.1 Testes de `getBatchMetrics` / parsing de métricas por OP
- [x] 6.2 Teste de navegação pós-SET_BATCH (widget test com provider overrides)
- [x] 6.3 Atualizar specs arquivadas após implementação (`openspec archive`)
