## Context

O firmware, ao aprovar uma peça, usa `sequencial_usado = s_batch.proximo_sequencial`, publica o resultado MQTT e **só então** incrementa `proximo_sequencial` e `aprovados`. O app gera o serial ITF a partir do `sequencial` recebido no payload `tipo: teste`.

O simulador (`simulateTestResult`) envia sempre `sequencial: batch.proximoSequencial` — valor fixo do `SET_BATCH` — ignorando aprovados anteriores. A 2ª aprovação gera o mesmo serial `0732600011`, `serialExists` bloqueia e o buffer fica com 1 etiqueta.

O `activeBatch` no Riverpod também não atualiza `proximoSequencial` após emissões, desalinhando UI e simulador do estado real do lote.

## Goals / Non-Goals

**Goals:**

- Cada aprovação no lote emite serial com sequencial único e crescente.
- Simulador dev reproduz o mesmo comportamento do firmware.
- Dashboard e Etiquetas mostram todos os seriais pendentes/emitidos da OP.

**Non-Goals:**

- Alterar formato ITF ou dígito verificador.
- Mudar regra de impressão em múltiplos de 3.
- Corrigir rota de rede da impressora (erro separado: subnet 192.168.1.x vs 192.168.51.x).

## Decisions

### 1. Fórmula do próximo sequencial no lote

**Decisão:** `sequencialEmitido = batch.proximoSequencial + aprovadosComSerialNoLote`

Onde `aprovadosComSerialNoLote` conta aprovações da OP com serial gerado (ou usa `metrics.aprovados` do SQLite para a OP).

Para MQTT real: confiar no `test.sequencial` do payload (fonte de verdade do firmware). Para simulador: calcular com a fórmula acima.

**Alternativa:** só incrementar no simulador — insuficiente se `activeBatch` ficar desatualizado na UI.

### 2. Atualizar `activeBatch` após emissão

**Decisão:** Após serial emitido com sucesso em `processTestResult`, se `device.activeBatch` corresponde à mesma OP:

```dart
batch.proximoSequencial = test.sequencial + 1;
```

Isso mantém o simulador e a UI alinhados sem depender só do SQLite.

### 3. Validação de duplicata

Manter `serialExists` — se firmware e app divergirem, alerta continua válido. Adicionar log/alerta mais claro quando duplicata ocorre no mesmo lote (possível bug de sequencial).

### 4. Visibilidade na UI

- **Batch Live Dashboard:** coluna/lista "Seriais emitidos" com chips dos seriais da OP (buffer + test_results).
- **Etiquetas:** manter lista atual; garantir que múltiplas entradas aparecem com OP e serial distintos.

## Risks / Trade-offs

- **[Risco] MQTT com sequencial errado do firmware** → App continua usando payload; duplicata alerta operador.
- **[Risco] Reprocessar mensagem MQTT duplicada** → `serialExists` idempotente; não duplica buffer.
- **[Trade-off] Contar aprovados via SQLite vs memória** → SQLite é fonte para métricas; `activeBatch` atualizado para hot path do simulador.

## Migration Plan

1. Extrair `nextBatchSequencial(batch, aprovadosNoLote)` helper.
2. Corrigir `simulateTestResult` e `processTestResult` (update activeBatch).
3. Adicionar lista de seriais no dashboard.
4. Testes: 4 simulações aprovadas → 4 buffer entries com seq 1..4.

Rollback: reverter helpers; sem migração de dados.

## Open Questions

- Exibir seriais reprovados (sem serial) no dashboard? → Mostrar só aprovados com serial.
