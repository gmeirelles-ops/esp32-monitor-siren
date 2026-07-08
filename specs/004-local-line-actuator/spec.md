# Feature Specification: Decisão local na linha e atuador físico

**Feature Branch**: `004-local-line-actuator`

**Created**: 2026-07-08

**Status**: Draft

**Input**: O ESP32 não deve esperar Firebase nem MQTT para aprovar/reprovar. Decisão local em milissegundos, atuador físico (relé/pistão/luz), MQTT assíncrono só para registro. Otimizar PZEM (leitura só de potência), dual-core (teste no Core 0, rede no Core 1). Flutter/Firebase como painel de configuração e dashboards.

## User Scenarios & Testing

### User Story 1 - Separação física imediata (Priority: P1)

Como operador de linha, preciso que o produto seja aprovado ou enviado ao refugo **no momento do teste**, sem depender de internet, para a esteira não parar.

**Why this priority**: Parada por latência de nuvem ou MQTT inviabiliza alta produtividade.

**Independent Test**: Desconectar broker/Wi-Fi durante teste; verificar que relé/atuador e LED respondem; resultado entra na fila offline.

**Acceptance Scenarios**:

1. **Given** lote ativo com limites válidos em NVS, **When** potência média está na faixa após ciclo de medição, **Then** firmware aciona saída de aprovação em &lt; 50 ms após fim da medição, **sem** aguardar MQTT.
2. **Given** broker offline, **When** teste conclui, **Then** veredito e contadores locais são atualizados e JSON enfileirado para publicação posterior.
3. **Given** reprovação, **When** medição termina fora da faixa, **Then** saída de refugo é acionada (GPIO dedicado ou relé configurável).

---

### User Story 2 - Tempo de ciclo otimizado (Priority: P1)

Como engenheiro de produção, preciso reduzir o tempo entre peça na bancada e decisão, para aumentar throughput.

**Why this priority**: PZEM a 9600 bps e ciclo de 5–15 s limitam linha rápida.

**Independent Test**: Medir latência fim-a-fim (botão → GPIO atuador) com otimizações habilitadas.

**Acceptance Scenarios**:

1. **Given** firmware com leitura direta do registrador de potência ativa, **When** uma amostra é solicitada, **Then** tempo médio de leitura UART ≤ 120 ms (vs baseline atual).
2. **Given** tarefa de teste pinada no Core 0, **When** Wi-Fi reconecta no Core 1, **Then** ciclo de teste em andamento não é bloqueado por stack de rede.

---

### User Story 3 - Configuração gerencial sem ser o cérebro (Priority: P2)

Como gerente, preciso alterar limites e parâmetros pelo app/Firebase e que o ESP32 aplique na **próxima** peça, sem o app aprovar cada teste.

**Why this priority**: Separação operação (edge) vs gestão (nuvem).

**Independent Test**: Alterar limites via `SET_BATCH` ou tópico de config; próximo teste usa novos valores.

**Acceptance Scenarios**:

1. **Given** app envia `SET_BATCH` com novos `potencia_min`/`potencia_max`, **When** firmware persiste em NVS, **Then** próximo teste usa limites novos localmente.
2. **Given** resultado `tipo:teste` publicado, **When** app recebe, **Then** app registra serial/etiqueta mas **não** recalcula veredito (confia no firmware).

---

### Edge Cases

- PZEM UART falha mid-test → `HARDWARE_FAULT`, atuador em estado seguro (refugo ou neutro configurável).
- Duplo acionamento de atuador se operador pressiona botão durante `TESTING`.
- Config MQTT chega durante teste → aplicar após ciclo ou rejeitar com `config_durante_teste`.
- Modo reteste: atuador de aprovação física pode não incrementar contador (política configurável).

## Requirements

### Functional Requirements

- **FR-001**: Veredito `APROVADO`/`REPROVADO` MUST ser calculado **somente no firmware** com limites locais (`potencia_min`, `potencia_max`).
- **FR-002**: Acionamento de GPIO (relé carga, relé refugo, LED) MUST ocorrer antes ou independentemente de `mqtt_publish`.
- **FR-003**: MUST existir GPIO ou relé configurável para **ejeção/refugo** (além do relé de carga da sirene).
- **FR-004**: Leitura PZEM SHOULD usar registrador de potência ativa apenas quando flag de otimização habilitada.
- **FR-005**: Tarefa crítica de teste SHOULD rodar pinada ao Core 0; MQTT/Wi-Fi no Core 1.
- **FR-006**: App MUST continuar como painel: `SET_BATCH`, calibração, dashboards — sem veto de teste em tempo real.
- **FR-007**: Fila offline MUST preservar `tipo:teste` quando broker indisponível (já existente; validar com atuador).

### Non-Functional Requirements

- **NFR-001**: Latência decisão → GPIO após última amostra válida: alvo &lt; 50 ms (exclui tempo de integração configurável).
- **NFR-002**: Linha MUST operar com broker down por janela configurável (ex.: 8 h) sem perder vereditos locais.

### Key Entities

- **LineActuatorConfig**: pinos GPIO, polaridade, tempo de pulso refugo.
- **TestCycleConfig**: duração, inrush discard, usar max vs média (política de veredito).
- **LocalBatchContext**: limites e contadores em NVS (existente).
- **TestResultEvent**: veredito + potência + timestamps para MQTT/Firestore.

## Success Criteria

- **SC-001**: 100% dos testes em bancada com MQTT desligado produzem veredito local + acionamento físico correto.
- **SC-002**: Redução ≥ 30% no tempo de leitura PZEM por amostra (benchmark documentado).
- **SC-003**: Zero regressão no fluxo app: serial/etiqueta apenas em `APROVADO` MQTT (ou fila offline replay).
- **SC-004**: Documentação de pinagem e modo seguro do atuador de refugo.

## Assumptions

- Hardware atual: ESP32 + PZEM-004T + 1 relé (carga). Segundo relé ou saída GPIO disponível para refugo.
- Política de veredito em produção: média no ciclo (hoje); calibração usa máximo (v1.7.7) — decisão de alinhar teste a max é escopo separado.
- Firebase não participa do caminho crítico de teste (já verdadeiro no app atual).
