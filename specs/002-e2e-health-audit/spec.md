# Feature Specification: Auditoria ponta a ponta — Diponto Sirene

**Feature Branch**: `002-e2e-health-audit`

**Created**: 2026-07-07

**Status**: Draft

**Input**: Analisar todo o projeto e verificar se está tudo OK para funcionar de ponta a ponta (firmware, app, MQTT, serial/etiqueta/laser, Firestore, operador).

## User Scenarios & Testing

### User Story 1 - Linha de teste física confiável (Priority: P1)

Como operador de produção, preciso configurar um lote, pressionar o botão uma vez e ver exatamente um resultado APROVADO ou REPROVADO, com serial gerado quando aprovado, para que nenhum produto passe sem rastreabilidade.

**Why this priority**: É o fluxo central da fábrica; falhas aqui param a linha ou geram recall.

**Independent Test**: SET_BATCH → 1 toque → 1 registro no painel com veredito claro e serial ITF (se aprovado).

**Acceptance Scenarios**:

1. **Given** lote ativo com limites válidos e heartbeat `fila: 0`, **When** o operador pressiona o botão uma vez, **Then** exatamente um teste aparece no painel com veredito APROVADO ou REPROVADO.
2. **Given** payload MQTT colado ou republicado da fila offline, **When** o mesmo sequencial chega duas vezes, **Then** o sistema registra o teste uma única vez.
3. **Given** potência fora da faixa, **When** o teste termina, **Then** o veredito é REPROVADO e nenhum serial é emitido.

---

### User Story 2 - Rastreabilidade local e cloud (Priority: P1)

Como supervisor, preciso que cada aprovação fique registrada localmente e sincronizada na nuvem com operador identificado, para auditoria e relatórios.

**Why this priority**: Rastreabilidade é requisito regulatório e de qualidade.

**Independent Test**: Aprovar 1 peça com sync ativo → documento Firestore com serial na hierarquia correta.

**Acceptance Scenarios**:

1. **Given** operador logado via PIN e sync ativo, **When** um teste é aprovado, **Then** o registro local contém operador e serial, e a fila de sync enfileira o evento.
2. **Given** sync concluído, **When** consulto a nuvem, **Then** existe `test_results/{numero_op}/seriais/{serial}` com dados do teste.
3. **Given** reprovação, **When** o teste é registrado, **Then** entra em `reprovadas/{sequencial}` sem serial.

---

### User Story 3 - Marcação física (etiqueta ou laser) (Priority: P2)

Como operador, preciso que o serial aprovado saia na etiqueta Zebra ou na gravação laser Diatu automaticamente, conforme o modo configurado no posto.

**Why this priority**: Serial no produto físico é a prova de rastreabilidade na linha.

**Independent Test**: Aprovar teste → etiqueta impressa (modo Zebra) ou item na fila laser (modo Diatu).

**Acceptance Scenarios**:

1. **Given** modo etiqueta Zebra configurado, **When** 3 aprovações acumulam no buffer, **Then** uma fileira de etiquetas é impressa.
2. **Given** modo laser configurado, **When** um teste é aprovado, **Then** o serial entra na fila de gravação TCP.
3. **Given** modo reteste ativo, **When** teste aprovado, **Then** nenhuma etiqueta nem gravação é emitida.

---

### User Story 4 - Observabilidade operacional (Priority: P2)

Como operador ou técnico, preciso ver claramente rejeições MQTT, alertas de hardware/NVS e versão do firmware, para diagnosticar paradas sem adivinhar.

**Why this priority**: Reduz tempo de parada e retrabalho.

**Independent Test**: Simular `lote_cheio` e `batch_nvs_fault` → mensagens legíveis na UI.

**Acceptance Scenarios**:

1. **Given** cota do lote atingida, **When** operador tenta novo teste, **Then** rejeição `lote_cheio` aparece com texto legível em português.
2. **Given** falha NVS no firmware, **When** alerta MQTT chega, **Then** banner visível no painel ao vivo.
3. **Given** bancada online, **When** consulto detalhes, **Then** versão de firmware reportada (ex.: 1.7.5) coincide com heartbeat.

---

### User Story 5 - Documentação e scripts alinhados (Priority: P3)

Como integrador ou técnico de TI, preciso que guias de produção e scripts E2E usem os mesmos tópicos MQTT e versões que o código atual, para evitar configuração errada.

**Why this priority**: Documentação desatualizada causa falhas silenciosas em novos postos.

**Independent Test**: Seguir PRODUCAO.md e script E2E sem encontrar tópicos legados `sirene/<device_id>/`.

**Acceptance Scenarios**:

1. **Given** checklist de produção, **When** técnico segue passo a passo, **Then** referências de firmware e tópicos MQTT estão corretas.
2. **Given** script E2E automatizado, **When** executado contra broker de teste, **Then** publica em `producao/bancada-NN/` e não em esquema legado.

---

### Edge Cases

- MQTT desconectado durante teste: resultado enfileirado no firmware e republicado ao reconectar.
- Heartbeat `fila > 0` antes do teste: testes antigos podem chegar em burst — dedupe no app.
- Duplo END_BATCH quando cota atingida (firmware + app).
- SNTP não sincronizado: `ts_unix: 0` no firmware; app usa hora local.
- PC sem SSE4.1: app Windows não inicia.
- Sync cloud desligado: produção local continua; cloud fica pendente.

## Requirements

### Functional Requirements

- **FR-001**: O fluxo completo MUST cobrir: login operador → SET_BATCH → teste físico → veredito → serial → marcação → sync cloud.
- **FR-002**: Cada teste físico MUST produzir exatamente um veredito APROVADO ou REPROVADO visível ao operador.
- **FR-003**: Aprovações MUST gerar serial ITF de 10 dígitos único por sequencial do lote.
- **FR-004**: Testes duplicados (mesmo OP + sequencial) MUST NOT ser registrados duas vezes.
- **FR-005**: Rejeições e alertas MQTT MUST ser exibidos em linguagem legível ao operador.
- **FR-006**: Sync cloud MUST seguir hierarquia `test_results/{op}/seriais/{serial}` quando habilitado.
- **FR-007**: Documentação de produção e scripts E2E MUST refletir firmware 1.7.5 e tópicos `{site}/bancada-NN/`.
- **FR-008**: CI local MUST passar (testes Flutter + host tests firmware) antes de release.

### Key Entities

- **Lote (Batch)**: OP, produto, limites, cota, sequencial, modo reteste.
- **Teste**: veredito, potência, sequencial, operador, serial opcional.
- **Serial ITF**: 10 dígitos derivados de produto + ano + sequencial.
- **Dispositivo (bancada)**: estado FSM, firmware, fila offline, RSSI.
- **SyncQueue**: fila local de eventos pendentes para Firestore.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% dos testes físicos na bancada de validação exibem veredito APROVADO ou REPROVADO (zero testes fantasma).
- **SC-002**: 1 toque no botão produz no máximo 1 novo registro de teste no app (dedupe incluído).
- **SC-003**: 100% das aprovações no checklist E2E geram serial e registro local.
- **SC-004**: Com sync ativo, 100% das aprovações do checklist aparecem em Firestore em até 5 minutos.
- **SC-005**: Zero referências a tópicos legados `sirene/<device_id>/` nos docs/scripts de produção após auditoria.
- **SC-006**: `./scripts/ci_local.sh` passa sem falhas.

## Assumptions

- Firmware de referência: **1.7.5** (ESP32 bancada).
- App de referência: **sirene_app** Windows desktop.
- Broker MQTT acessível (LAN ou WSS).
- sirene_manager_app é experimental e fora do fluxo crítico de produção.
- Validação física na bancada requer presença de operador e hardware real.
- Deploy de binário Windows exige confirmação explícita do usuário (regra do projeto).

## Dependencies

- Feature anterior: `specs/001-fw-sw-compat` (contratos MQTT e correções de parser).
- OpenSpec: `openspec/specs/firestore-sync`, `openspec/specs/label-printing`, `openspec/specs/mqtt-messaging`.
- Guia de fábrica: `docs/PRODUCAO.md`.
