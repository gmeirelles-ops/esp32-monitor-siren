# Feature Specification: Auditoria de Compatibilidade Firmware × Software

**Feature Branch**: `001-fw-sw-compat`

**Created**: 2026-07-07

**Status**: Draft

**Input**: Verificar se o firmware está correspondente ao software — sem diferenças que possam causar incompatibilidade, erro, falha de validação ou aprovação de produto.

## User Scenarios & Testing

### User Story 1 - Aprovação de produto confiável (Priority: P1)

Como operador de produção, preciso que cada teste aprovado no firmware gere serial, etiqueta e registro no app, para que nenhum produto aprovado seja perdido.

**Why this priority**: Perda de aprovação = produto sem rastreabilidade e possível retrabalho/recall.

**Independent Test**: Executar teste físico com lote ativo; verificar que MQTT `tipo:teste` com `veredito:APROVADO` resulta em serial ITF, registro local e sync Firestore.

**Acceptance Scenarios**:

1. **Given** lote ativo com limites válidos, **When** o operador pressiona o botão e a potência está na faixa, **Then** firmware publica `APROVADO` e o app gera serial e grava teste.
2. **Given** payload MQTT colado/corrompido no tópico `status`, **When** chega resultado de teste, **Then** o parser do app recupera o JSON e processa aprovação (não descarta silenciosamente).

---

### User Story 2 - Configuração de lote alinhada (Priority: P1)

Como operador, preciso que `SET_BATCH` enviado pelo app configure o firmware com os mesmos limites de potência, tempo e sequencial usados na validação.

**Why this priority**: Divergência de limites ou sequencial causa reprovação indevida ou serial duplicado.

**Independent Test**: Comparar campos de `SET_BATCH` publicados pelo app com validação `pure_batch_fields_valid` do firmware.

**Acceptance Scenarios**:

1. **Given** produto cadastrado com tolerância ±X%, **When** o operador inicia lote, **Then** `potencia_min`/`potencia_max` enviados coincidem com os limites do cadastro (2 casas decimais).
2. **Given** firmware com lote ativo na mesma OP, **When** app reenvia `SET_BATCH`, **Then** `proximo_sequencial` do firmware nunca regride (regra `max(atual, payload)`).

---

### User Story 3 - Diagnóstico de falhas visível (Priority: P2)

Como operador/supervisor, preciso ver rejeições e falhas de hardware/NVS no app para entender por que um teste não foi aceito.

**Why this priority**: Rejeições silenciosas ou não exibidas bloqueiam produção sem causa aparente.

**Independent Test**: Simular/publicar cada `motivo` de rejeição e alertas; verificar exibição no app.

**Acceptance Scenarios**:

1. **Given** lote com cota atingida, **When** operador tenta novo teste, **Then** firmware publica `lote_cheio` e app exibe rejeição.
2. **Given** falha NVS no firmware (`batch_nvs_fault`), **When** alerta é publicado, **Then** o operador é notificado no app (gap atual: não implementado).

---

### Edge Cases

- Duplo `END_BATCH` quando cota é atingida (firmware auto-encerra + app auto-encerra).
- Modo reteste: aprovação não incrementa contadores no firmware nem gera serial no app.
- Heartbeat atrasado após `SET_BATCH` sem parse de ACK `tipo:batch`.
- `ts_unix: 0` quando SNTP não sincronizado (app usa hora local).
- Ensaio com segundos não múltiplos de 60: firmware aceita, app UI não permite.

## Requirements

### Functional Requirements

- **FR-001**: Tópicos MQTT do app e firmware MUST usar `{site}/bancada-{NN}/{suffix}`.
- **FR-002**: Comandos críticos (`SET_BATCH`, `END_BATCH`, `START_CALIBRATION`) MUST ter campos JSON idênticos entre app e firmware.
- **FR-003**: Resultado de teste MUST usar `veredito` `APROVADO`|`REPROVADO` e campos obrigatórios acordados.
- **FR-004**: Lógica de aprovação no firmware MUST ser `potencia_min ≤ média ≤ potencia_max` (inclusivo); app MUST confiar no veredito MQTT.
- **FR-005**: Em modo reteste, firmware MUST NOT incrementar `aprovados`/`proximo_sequencial`; app MUST NOT emitir serial.
- **FR-006**: Parser MQTT do app MUST recuperar resultados de teste de payloads colados/corrompidos.
- **FR-007**: Documentação OpenSpec (`mqtt-messaging`) MUST ser atualizada para refletir esquema de tópicos atual.
- **FR-008**: Alertas `batch_nvs_fault` MUST ser exibidos no app (gap a corrigir).
- **FR-009**: ACK `tipo:batch` SHOULD ser parseado para confirmar `SET_BATCH` (melhoria recomendada).

### Key Entities

- **BatchConfig**: OP, produto, ano, limites, cota, sequencial, modo reteste.
- **TestResultMessage**: veredito, potência, sequencial, aprovados_no_lote.
- **RejectionMessage**: motivo padronizado firmware→app.
- **HeartbeatMessage**: estado FSM, versão firmware, contadores de lote.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% dos campos obrigatórios de `SET_BATCH` e `tipo:teste` coincidem entre firmware 1.7.5 e app atual.
- **SC-002**: Zero perda de aprovação em teste E2E com broker real (serial gerado para cada `APROVADO`).
- **SC-003**: Todos os 30+ códigos `motivo` de rejeição do firmware têm cobertura de teste ou UI no app.
- **SC-004**: Documentação OpenSpec alinhada ao esquema `{site}/bancada-NN/...`.

## Assumptions

- Firmware de referência: `sirene-validator` v1.7.5 (`board_config.h`).
- App de referência: `sirene_app` (Flutter desktop).
- Broker MQTT 3.1.1, site padrão `producao`.
- Não existe campo `protocol_version` em JSON — compatibilidade é implícita por versão de firmware.
