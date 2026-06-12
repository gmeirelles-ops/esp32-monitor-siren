## Context

Hoje a `BatchScreen` concentra formulário de `SET_BATCH`, barra de progresso simples e card do último teste. Dados históricos do lote existem em `test_results` (SQLite) com `numero_op`, `veredito`, `potencia_media`, `sequencial`, `operador` e `serial`, mas não há consulta reativa por OP nem tela dedicada. O `production-dashboard` já implementa gráficos de barras customizados (`_BarChart`) reutilizáveis. O firmware publica resultados em `sirene/<id>/status` com `tipo: teste` e heartbeat a cada 30s; confirmação de `SET_BATCH` foi recentemente ajustada para aguardar rejeição em vez de heartbeat.

## Goals / Non-Goals

**Goals:**

- Após `SET_BATCH` bem-sucedido, navegar para `BatchLiveScreen` com visão completa do lote corrente.
- Exibir métricas ao vivo: aprovados, reprovados, yield, progresso vs meta, operador, estado FSM do dispositivo.
- Gráfico de potência por teste e lista cronológica alimentados por `watchTestsByOp(numeroOp)`.
- Atualização em tempo real quando chegam mensagens MQTT ou quando simulador de dev injeta resultados.
- Modo dev (somente debug): simular testes com potências fictícias sem PZEM, exercitando serial, etiquetas e UI.

**Non-Goals:**

- Substituir o Painel global de produção (permanece agregado por período).
- Simulação em builds de release/produção.
- Alterar contrato MQTT de resultados de teste.
- Relatórios exportáveis ou sync Firestore específico do dashboard (reusa fila existente).

## Decisions

### 1. Navegação: configuração → dashboard

**Decisão:** `BatchScreen` permanece como formulário de configuração. Sucesso em `sendSetBatch` faz `Navigator.push` para `BatchLiveScreen(numeroOp, deviceId)` com `MaterialPageRoute`.

**Alternativa considerada:** substituir a aba Lote inteira pelo dashboard — rejeitada porque operador ainda precisa configurar novo lote sem perder contexto da navegação principal.

### 2. Fonte de dados do dashboard

**Decisão:** Combinar três fontes:

| Fonte | Dados |
|-------|--------|
| `devicesProvider` | Estado FSM, `activeBatch`, último teste MQTT, rejeições |
| `watchTestsByOp(numeroOp)` | Histórico persistido no SQLite |
| `authStateProvider` | E-mail do operador autenticado (nuvem) ou "local" |

Métricas derivadas em `batchLiveMetricsProvider` (Riverpod): `aprovados`, `reprovados`, `totalTestado`, `yield`, `pendentes = quantidadeTotal - aprovados`.

**Alternativa:** só MQTT em memória — rejeitada; perde histórico ao trocar de tela.

### 3. Gráficos

**Decisão:** Reutilizar padrão visual do `DashboardScreen` (`_BarChart` / barras coloridas por veredito). Adicionar faixa sombreada ou linhas tracejadas para `potencia_min` / `potencia_max` do produto.

**Alternativa:** adicionar `fl_chart` — rejeitada para manter consistência e evitar nova dependência.

### 4. Simulador de desenvolvimento (app)

**Decisão:** Em `kDebugMode` (ou `AppConfig.devSimulatorEnabled`), botão "Simular teste" na `BatchLiveScreen` chama `DevicesNotifier.simulateTestResult(deviceId)` que:

1. Gera `potencia_media` aleatória (50% dentro dos limites, 50% fora).
2. Reutiliza `_handleMessage` internamente ou extrai handler compartilhado com payload JSON idêntico ao firmware.
3. Persiste em SQLite, atualiza contadores e dispara pipeline de etiquetas como teste real.

**Alternativa:** publicar no broker MQTT local — rejeitada; mais frágil e exige broker.

### 5. Simulador de desenvolvimento (firmware, opcional)

**Decisão:** Flag Kconfig `CONFIG_DEV_MOCK_PZEM` (default n) em `sirene-validator`. Quando ativa, `pzem_measure_cycle` retorna amostras sintéticas com média configurável ou aleatória; relé ainda aciona para feedback físico.

**Alternativa:** só simulador no app — insuficiente para validar botão físico e FSM completa; manter ambos.

### 6. Retorno à configuração

**Decisão:** `BatchLiveScreen` tem AppBar com voltar; se lote encerrado (`END_BATCH` ou estado `IDLE`), snackbar e pop opcional. `BatchScreen` detecta `activeBatch` e exibe banner "Lote em andamento — Ver dashboard".

## Risks / Trade-offs

- **[Risco] Contadores MQTT vs SQLite dessincronizados** → Usar SQLite como fonte de verdade para histórico; MQTT apenas para último estado e FSM.
- **[Risco] Simulador gera seriais reais** → Exibir banner "MODO DEV" e prefixar serial simulado ou marcar `operador: dev-simulator` nos registros.
- **[Risco] Gráfico com muitos testes** → Limitar gráfico aos últimos 50 testes da OP; lista completa com scroll.
- **[Trade-off] Firmware mock opcional** → Tarefa separada; app funciona sem reflash.

## Migration Plan

1. Implementar query `watchTestsByOp` e provider de métricas.
2. Criar `BatchLiveScreen` e conectar navegação pós-`SET_BATCH`.
3. Enxugar `BatchScreen` (remover cards de progresso detalhados).
4. Adicionar simulador app em debug.
5. (Opcional) Firmware `CONFIG_DEV_MOCK_PZEM` em branch separada ou mesma change.

Rollback: reverter navegação; `BatchScreen` volta ao comportamento anterior sem perda de dados.

## Open Questions

- Prefixar OP de testes simulados com `DEV-` para facilitar limpeza no SQLite?
- Permitir múltiplos dispositivos na mesma OP no dashboard (fase 2)?
