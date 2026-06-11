## Context

O módulo `offline_queue` grava apenas o corpo JSON em SPIFFS (`/storage/q_NNNN.json`) e `drain_queue()` publica tudo via `s_publish_fn("status", json)`. Porém `publish_or_queue()` em `main.c` enfileira também mensagens de `alerta` e `calibracao`, que o broker e o app Flutter esperam em tópicos distintos.

Comandos MQTT chegam em `on_mqtt_command()`, são copiados para `s_work_queue` e processados em `worker_task()` — a mesma tarefa que executa testes de vários segundos e calibração. Guards como `handle_end_batch()` verificam `STATE_TESTING` no momento do processamento; após o teste, o estado volta a `BATCH_READY` e um `END_BATCH` enfileirado durante o teste é aplicado indevidamente.

`pzem_measure_cycle()` chama `pzem_read_power_w()` uma vez por intervalo de 100 ms e retorna `uart_error` na primeira falha, abortando testes longos por ruído UART momentâneo.

`quantidade_total` é parseado em `parse_set_batch()` e exposto em telemetria, mas `run_test_cycle()` não verifica se a meta já foi atingida.

## Goals / Non-Goals

**Goals:**

- Preservar tópico MQTT por entrada da fila offline e drenar com roteamento correto.
- Impedir execução tardia de comandos destrutivos enfileirados durante teste/calibração.
- Tolerar falhas UART transitórias no PZEM sem abortar o ciclo inteiro quando houver amostras válidas.
- Bloquear testes além de `quantidade_total` com sinalização clara ao operador.
- Cobrir regras puras com testes host existentes (`pure_logic`, `scripts/run_host_tests.sh`).

**Non-Goals:**

- Mutex global em `s_batch` (mutações já concentradas na worker task; fora do escopo desta change).
- TLS MQTT, OTA assinado, CI GitHub Actions ou mudanças no app Flutter.
- Encerramento automático de lote ao atingir `quantidade_total` (continua exigindo `END_BATCH` explícito).
- Migração em massa de entradas SPIFFS legadas além do fallback `status`.

## Decisions

### 1. Formato da entrada offline: arquivo JSON envelope

**Decisão:** cada arquivo SPIFFS passa a conter `{"topic":"<suffix>","payload":<json>}` (payload como objeto JSON incorporado ou string JSON parseável).

**Alternativas:** arquivo `.topic` paralelo (dois writes não atômicos); prefixo texto `topic|json` (menos legível para debug).

**Compatibilidade:** se `offline_queue_peek` detectar JSON sem campo `topic`, assume `status` (entradas gravadas antes da atualização).

### 2. API `offline_queue_push(topic_suffix, json)`

**Decisão:** estender a assinatura pública; `publish_or_queue()` passa o sufixo recebido. `drain_queue()` lê tópico + payload e chama `s_publish_fn(topic, payload_serializado)`.

**Alternativa:** callback que reconstrói tópico a partir de campo `tipo` no JSON — frágil (alertas vs status compartilham estruturas similares).

### 3. Rejeição de comando na chegada (enqueue), não no dequeue

**Decisão:** em `on_mqtt_command()`, parse mínimo do campo `cmd` (sem alocar cJSON completo se possível, ou parse rápido). Para `SET_BATCH`, `END_BATCH`, `START_CALIBRATION`, `OTA_UPDATE`:

- se `state == TESTING` **ou** `s_calibrating == true` → `mqtt_bridge_publish_rejection("cmd_durante_teste")` e **não** enfileirar.

**Alternativa:** marcar work item com flag `queued_during_test` — mais estado, mesmo efeito.

Comandos já rejeitados em `process_mqtt_payload()` por campos inválidos permanecem no fluxo atual (enfileirados apenas se passarem o guard de estado).

### 4. PZEM: retentativas por intervalo de amostra

**Decisão:** constante `PZEM_SAMPLE_READ_RETRIES` (padrão 3) em `board_config.h`. Em cada tick de 100 ms, tentar leitura até N vezes com `vTaskDelay(10 ms)` entre tentativas. Se todas falharem, **pular** aquele intervalo (não incrementar `sample_count`). Ao fim do ciclo, falhar com `uart_error` somente se `sample_count == 0`.

**Alternativa:** falhar ciclo na primeira amostra esgotada — comportamento atual, pouco resiliente.

### 5. Cota de lote em `pure_logic`

**Decisão:** adicionar `pure_batch_quota_reached(aprovados, quantidade_total)` retornando true quando `quantidade_total > 0 && aprovados >= quantidade_total`. Usado no início de `run_test_cycle()`; se true, sinal LED distinto (ex.: três bips curtos ou reutilizar `FEEDBACK_REJECTED`) e publicar rejeição `lote_cheio` em `status` se MQTT disponível (não enfileirar rejeição operacional efêmera).

**Alternativa:** incrementar reprovados fictícios — confunde analytics.

## Risks / Trade-offs

- **[Envelope JSON aumenta tamanho SPIFFS]** → payloads atuais <512 B; envelope cabe no buffer existente; manter `OFFLINE_QUEUE_MAX` inalterado.
- **[Parse de cmd na ISR path / callback MQTT]** → parse leve de string (`strstr`/`strcmp` em `"cmd"`) antes do enqueue; payload limitado a tamanho já validado.
- **[Entradas legadas sem tópico]** → fallback `status`; alertas/calibração perdidos antes do upgrade não são recuperáveis (aceitável).
- **[Pular amostras PZEM reduz precisão da média]** → preferível a abortar lote inteiro; operador ainda vê reprovação se média sair da faixa.

## Migration Plan

1. Flash firmware novo em um posto piloto.
2. Fila SPIFFS existente continua drenável (fallback `status`).
3. Novas entradas passam a carregar tópico correto.
4. Validar com broker: publicar `END_BATCH` durante teste → rejeição imediata; offline de alerta → reconexão publica em `alerta`.

## Open Questions

- Nenhuma bloqueante. LED específico para `lote_cheio` pode reutilizar padrão existente até feedback dedicado ser definido com operação.
