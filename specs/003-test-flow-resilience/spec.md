# Feature Specification: Resiliência do fluxo de teste

**Feature Branch**: `003-test-flow-resilience`  
**Created**: 2026-07-08  
**Status**: Draft  
**Input**: Eliminar efeito de "pular sirene" quando MQTT/internet está lenta.

## User Scenarios & Testing

### User Story 1 — Nenhuma sirene pulada por latência (Priority: P1)

Como operador, preciso que cada teste físico apareça no app, mesmo com MQTT lento ou múltiplas reprovações no mesmo sequencial.

**Acceptance Scenarios**:

1. **Given** 3 reprovados consecutivos no mesmo `sequencial`, **When** MQTT chega com `ts_ms` distintos, **Then** 3 registros aparecem no painel.
2. **Given** replay MQTT da fila offline com mesmo `ts_ms`, **When** app processa duas vezes, **Then** apenas 1 registro é gravado.
3. **Given** aprovação com impressora lenta, **When** teste chega, **Then** veredito visível antes da etiqueta.

### User Story 2 — Feedback imediato no painel (Priority: P1)

Como operador, preciso ver "Testando…" e "Aguardando MQTT" para não pressionar a próxima sirene antes do resultado.

**Acceptance Scenarios**:

1. **Given** firmware em TESTING, **When** heartbeat imediato chega, **Then** painel mostra "Testando…".
2. **Given** `fila > 0` no heartbeat, **When** operador olha o painel, **Then** vê indicador de fila offline.
3. **Given** MQTT desconectado, **When** sem resultado, **Then** mensagem clara de sem conexão.

### User Story 3 — Firmware publica estado no ciclo (Priority: P2)

Como app, preciso receber heartbeat `TESTING`/`BATCH_READY` imediatamente após início/fim do teste.

**Acceptance Scenarios**:

1. **Given** botão pressionado, **When** teste inicia, **Then** heartbeat `estado: TESTING` em < 2s.
2. **Given** teste concluído, **When** resultado publicado, **Then** heartbeat `BATCH_READY` imediato.

### User Story 4 — Fila offline sem confusão (Priority: P2)

Como operador, preciso entender quando resultados estão pendentes de sincronização MQTT.

**Acceptance Scenarios**:

1. **Given** broker offline, **When** 2 testes na bancada, **Then** `fila` incrementa e app mostra contador.
2. **Given** reconexão, **When** fila drena, **Then** dedupe por `ts_ms` evita duplicatas fantasma.

## Requirements

### Functional Requirements

- **FR-001**: App MUST deduplicar testes por `(numero_op, ts_ms)` quando `ts_ms` presente.
- **FR-002**: App MUST gravar SQLite antes de etiqueta/sync.
- **FR-003**: Firestore reprovadas MUST usar id derivado de `ts_ms`.
- **FR-004**: Firmware MUST publicar heartbeat imediato ao iniciar/terminar teste.
- **FR-005**: Painel operador MUST mostrar estados Testando e Aguardando MQTT.

### Key Entities

- `TestResult.firmwareTsMs` — timestamp único do firmware
- `TestResultMessage.tsMs` / `tsUnix` — campos MQTT parseados
