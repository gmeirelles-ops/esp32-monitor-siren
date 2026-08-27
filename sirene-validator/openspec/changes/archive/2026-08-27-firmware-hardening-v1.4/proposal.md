## Why

A análise do firmware v1.3.0 identificou lacunas de robustez e observabilidade que podem causar perda silenciosa de comandos MQTT, strings corrompidas em `SET_BATCH`, calibração incompleta offline e divergência entre FSM de runtime e testes host. Elevar para v1.4 fecha esses gaps sem alterar o hardware de bancada (GPIO 0 do botão permanece).

## What Changes

- Corrigir cópia de strings em `SET_BATCH` (`strncpy` → cópia segura com null terminator).
- Validar campos de `SET_BATCH` (ranges, formato, `potencia_min` < `potencia_max`).
- Publicar **ACK** MQTT ao configurar lote com sucesso.
- Documentar e preservar semântica de `SET_BATCH`: reenvio com mesmo `numero_op` mantém `aprovados`; OP diferente reinicia contadores.
- Mover ciclo PZEM (teste/calibração) para **task dedicada** — `worker_task` deixa de bloquear por segundos.
- Rejeitar comandos MQTT quando fila de trabalho estiver cheia (em vez de descartar silenciosamente).
- Amostras de calibração via `publish_or_queue` (offline-first como demais mensagens).
- Guard de reconexão MQTT (uma task/timer de reconnect por vez).
- Heartbeat enriquecido com contexto do lote ativo (`numero_op`, `sequencial`, `aprovados`).
- `state_machine` delega regras de transição para `pure_logic` (fonte única).
- Encerrar lote automaticamente ao atingir `quantidade_total` aprovados (`END_BATCH` implícito + notificação).
- Testes host para parsing/validação de `SET_BATCH`.
- Bump `FIRMWARE_VERSION` para `1.4.0`.

## Explicitly Out of Scope

- **GPIO do botão** — permanece `GPIO_BUTTON 0` para bancada de teste atual.
- MQTT TLS/autenticação, portal HTTPS, criptografia NVS (aceitos para LAN industrial isolada; change futuro se necessário).
- Refatoração total de `main.c` em múltiplos módulos (apenas extrações mínimas ligadas às mudanças acima).

## Capabilities

### New Capabilities

- `mqtt-batch-validation`: Validação e cópia segura de campos `SET_BATCH`
- `mqtt-batch-ack`: Confirmação explícita de lote configurado
- `pzem-worker-task`: Medição PZEM fora da worker queue
- `mqtt-queue-guard`: Rejeição quando fila interna cheia
- `telemetry-batch-fields`: Campos de lote no heartbeat

### Modified Capabilities

- `offline-queue`: Amostras de calibração enfileiradas offline
- `mqtt-reconnect`: Reconnect sem spawn duplicado de tasks
- `batch-lifecycle`: Semântica `SET_BATCH` e auto-encerramento por cota
- `state-machine`: Delegação para `pure_logic`
- `host-tests`: Casos de parsing JSON de batch

## Impact

| Área | Impacto |
|------|---------|
| `main/main.c` | Parsing batch, ACK, delegação de teste/calibração |
| `components/pzem/` | Possível API para task dedicada |
| `components/mqtt_bridge/` | Guard de reconnect |
| `components/telemetry/` | Payload heartbeat expandido |
| `components/state_machine/` | Chama `pure_logic` |
| `components/pure_logic/` | Novas funções de validação batch |
| `host_tests/` | Novos testes de parsing |
| `docs/GUIA_COMPLETO.md`, `docs/TESTING.md` | Contratos MQTT atualizados |
| App Flutter | Pode consumir ACK e heartbeat enriquecido (sem breaking change obrigatório) |
