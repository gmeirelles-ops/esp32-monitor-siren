# Feature Specification: Veredito imediato no painel de produção

**Feature Branch**: `005-immediate-live-verdict`

**Created**: 2026-07-08

**Status**: Draft

**Input**: Várias sirenes foram testadas na OP 1001; o MQTT do broker mostra `veredito: APROVADO` e `aprovados_no_lote: 6`, mas o painel ao vivo permanece em "Testando", "Aguarde o resultado" ou "Falha hardware", com 0 aprovados / 0 reprovados e lista de testes recentes vazia. O operador precisa ver aprovação ou reprovação **na hora**, sem depender de nuvem lenta ou JSON quebrado.

## Problem Statement (observado em produção)

- Payloads MQTT no tópico `status` chegam **colados e corrompidos** (vários `{"tipo":"teste"...}` concatenados, campos `id_produto`/`ano` truncados, aspas duplicadas).
- O painel Flutter só atualiza contadores e lista de testes quando consegue **parsear e gravar** `tipo:teste` — se o JSON falha, o operador vê zero resultados mesmo com mensagens visíveis no broker.
- O estado **"Testando"** pode persistir após o fim físico do teste quando o heartbeat muda mas `tipo:teste` não é processado.
- **Falha hardware** no painel bloqueia o fluxo operacional e mascara resultados já decididos no dispositivo.

## User Scenarios & Testing

### User Story 1 — Veredito visível em segundos (Priority: P1)

Como operador na bancada, preciso ver **APROVADO** ou **REPROVADO** no painel ao vivo logo após o teste terminar, para saber se posso pegar a próxima peça.

**Why this priority**: Sem feedback imediato, a linha para ou o operador repete testes desnecessários.

**Independent Test**: Executar 5 testes seguidos na OP ativa; cada um deve aparecer no painel em até 3 segundos após o LED da bancada indicar resultado.

**Acceptance Scenarios**:

1. **Given** lote OP 1001 ativo e bancada online, **When** uma sirene é testada e aprovada fisicamente (LED verde), **Then** o painel mostra o último teste como APROVADO e incrementa contador de aprovados em até 3 segundos.
2. **Given** lote ativo, **When** uma sirene é reprovada (LED vermelho), **Then** o painel mostra REPROVADO e incrementa reprovados sem gerar etiqueta.
3. **Given** MQTT lento mas heartbeat chegando, **When** o teste termina no dispositivo, **Then** o painel **não** fica preso em "Testando" além de 10 segundos após o fim do ciclo.

---

### User Story 2 — Resiliência a MQTT corrompido (Priority: P1)

Como operador, preciso que resultados apareçam mesmo quando o broker entrega JSON colado ou malformado (como visto na OP 1001).

**Why this priority**: Evidência de produção mostra `tipo:teste` concatenado 3–4 vezes no mesmo payload.

**Independent Test**: Reproduzir payload colado do broker; painel deve extrair um único resultado válido com veredito e contadores corretos.

**Acceptance Scenarios**:

1. **Given** payload `status` com dois ou mais JSON `tipo:teste` colados, **When** o app recebe a mensagem, **Then** extrai **um** resultado com `veredito`, `sequencial`, `potencia_media` e `aprovados_no_lote` coerentes.
2. **Given** payload com campos `ano`/`id_produto` truncados no objeto final mas presentes no prefixo colado, **When** o app processa, **Then** recupera identidade do produto e grava o teste.
3. **Given** payload irrecuperável após sanitização, **When** o app não consegue parsear `tipo:teste`, **Then** usa **fonte alternativa** (heartbeat com resumo do último teste) para atualizar o painel e registra alerta técnico.

---

### User Story 3 — Contadores alinhados com a bancada (Priority: P1)

Como supervisor, preciso que `0/10` no painel reflita os aprovados reais do lote, não apenas o que o SQLite conseguiu parsear.

**Why this priority**: MQTT mostrou `aprovados_no_lote: 6` enquanto o painel mostrava `0/10`.

**Acceptance Scenarios**:

1. **Given** heartbeat ou resultado com `aprovados_no_lote: N`, **When** o painel renderiza progresso do lote, **Then** exibe **N** aprovados (limitado por `quantidade_total` quando aplicável).
2. **Given** divergência entre contador local do app e `aprovados_no_lote` do firmware, **When** chega mensagem mais recente do firmware, **Then** o painel reconcilia para o valor do firmware.
3. **Given** reprovações sem incremento de aprovados, **When** listadas no painel, **Then** entram em contador de reprovados e em "testes recentes".

---

### User Story 4 — Falha hardware não esconde resultados (Priority: P2)

Como operador, preciso entender se a bancada está realmente inoperante ou se só o painel está desatualizado.

**Acceptance Scenarios**:

1. **Given** alerta de falha hardware ativo, **When** o operador abre o painel, **Then** vê causa clara e instrução (ex.: verificar PZEM/cabo) **sem** apagar testes já gravados na sessão.
2. **Given** recuperação de hardware (`evento: recuperado`), **When** heartbeat volta a `BATCH_READY`, **Then** painel sai de "Falha hardware" e aceita novo teste.
3. **Given** falha durante teste, **When** ciclo aborta, **Then** painel mostra reprovação ou falha explícita — não "Aguarde resultado" indefinidamente.

---

### User Story 5 — Origem única de publicação MQTT (Priority: P2)

Como sistema, preciso impedir que a fila offline ou reconexão publique JSON colado no broker.

**Acceptance Scenarios**:

1. **Given** fila offline com N mensagens, **When** a rede retorna, **Then** cada mensagem é publicada como **um** JSON válido por pacote MQTT (sem concatenação).
2. **Given** publicação de `tipo:teste`, **When** inspecionado no broker, **Then** payload é JSON único parseável por ferramentas padrão.

---

## Edge Cases

- Mesmo `sequencial` com várias reprovações e depois aprovação (reteste) — painel lista todas com `ts_ms` distintos.
- App reiniciado no meio do lote — ao reconectar MQTT, reconcilia histórico e contadores.
- Múltiplas bancadas no mesmo broker — resultado só atualiza a bancada correta (`bancada-NN`).
- Lote com meta 10 e 6 aprovados no firmware — painel mostra `6/10`, não `0/10`.
- Operador em modo reteste — veredito visível mas contador de meta não avança.

## Requirements

### Functional Requirements

- **FR-001**: O painel ao vivo MUST exibir o veredito do último teste em até **3 segundos** após o dispositivo concluir o ciclo (medido do fim do teste físico ou do heartbeat `BATCH_READY`, o que ocorrer primeiro).
- **FR-002**: O sistema MUST atualizar contadores de aprovados e reprovados no painel para cada teste concluído, independentemente da impressão de etiqueta.
- **FR-003**: O app MUST recuperar `tipo:teste` de payloads MQTT colados/corrompidos nos padrões observados em produção (concatenação, campos vazios, `ano` no prefixo).
- **FR-004**: O firmware MUST publicar no heartbeat, ao fim de cada teste, um **resumo do último resultado** (`veredito`, `potencia_media`, `sequencial`, `aprovados_no_lote`, `ts_ms`) para o app não depender exclusivamente de `tipo:teste` no tópico `status`.
- **FR-005**: O app MUST usar o resumo do heartbeat para atualizar o painel quando `tipo:teste` não for parseável em até 2 segundos após `BATCH_READY`.
- **FR-006**: O firmware MUST garantir que a fila offline publique **uma mensagem JSON por envio MQTT**, sem concatenação de corpos.
- **FR-007**: O painel MUST sair do estado "Testando / Aguarde resultado" quando receber veredito por qualquer canal válido (teste parseado ou resumo no heartbeat).
- **FR-008**: Testes recentes MUST listar pelo menos os últimos 20 resultados da OP ativa com veredito, potência e horário.
- **FR-009**: O sistema MUST registrar em log diagnóstico quando um payload `status` contém `tipo` mas não gera resultado gravado (para suporte).

### Non-Functional Requirements

- **NFR-001**: Recuperação de JSON colado MUST ser determinística (mesmo payload → mesmo resultado).
- **NFR-002**: Atualização do painel MUST ocorrer na thread UI sem bloquear impressão de etiquetas.

### Key Entities

- **LastTestSummary**: veredito, potência, sequencial, aprovados no lote, timestamp — espelho do último ciclo no firmware.
- **LiveBatchProgress**: aprovados, reprovados, meta, rendimento — visão operacional da OP.
- **MqttStatusPayload**: mensagem bruta no tópico status (pode estar corrompida).
- **TestResultRecord**: registro persistido no app por teste concluído.

## Success Criteria

- **SC-001**: Em teste de bancada com 10 sirenes, **100%** dos vereditos físicos (LED) aparecem no painel em até 3 segundos.
- **SC-002**: Payloads colados reproduzidos a partir de logs de produção (incl. OP 1001) resultam em **≥ 95%** de parse ou recuperação via heartbeat.
- **SC-003**: Contador `aprovados_no_lote` no painel diverge do firmware em **menos de 1%** dos testes em sessão de 1 hora.
- **SC-004**: Zero ocorrências de "Testando" por mais de 15 segundos após fim do ciclo com bancada online.
- **SC-005**: Operadores reportam que conseguem identificar aprovação/reprovação **sem abrir o broker MQTT**.

## Assumptions

- A decisão de aprovação/reprovação **já é local no ESP32** (feature 004); o gap é **exibição no painel**, não recálculo de veredito.
- O operador continua usando **botão + relé**; não é necessário atuador de esteira para esta feature.
- O broker MQTT atual (`mqtt.diponto.com`) permanece; melhorias focam em payload válido e caminhos redundantes no app.
- Etiqueta/serial podem continuar assíncronos; veredito no painel é prioridade sobre impressão.

## Out of Scope

- Redesenho completo do dashboard gerencial / Firebase analytics.
- Mudança de política de veredito (média vs máxima).
- Atuador físico de refugo em esteira.

## Dependencies

- Feature **003-test-flow-resilience** (dedupe `ts_ms`, estados Testando).
- Feature **004-local-line-actuator** (veredito local, ordem GPIO antes de MQTT).
- Contratos MQTT existentes em `specs/001-fw-sw-compat`.
