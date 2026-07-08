# Research: Decisão local na linha e atuador físico

**Feature**: 004-local-line-actuator  
**Date**: 2026-07-08

## R1 — O firmware já decide localmente?

**Decision**: Sim. Não é mudança de paradigma — é **formalização + extensão**.

**Evidência** (`batch_cmd.c`):

1. `pzem_measure_cycle` coleta potência
2. `pure_verdict_approved(average_w, pot_min, pot_max)` no firmware
3. `led_feedback_signal(APPROVED|REJECTED)` e `relay_set` **antes** de `publish_test_result`
4. App (`processTestResult`) confia em `veredito` MQTT — não recalcula faixa

**Rationale**: Evita duplicar lógica e retrabalho de spec; foco em gaps reais.

**Alternatives considered**: Mover veredito para app — **rejeitado** (latência, offline, segurança).

---

## R2 — PZEM: leitura só de potência

**Decision**: Adicionar `pzem_read_active_power_w()` que mantém request Modbus atual (função 0x04, 10 registradores) mas **documenta** que já extrai só word de potência; avaliar request reduzido (2 registradores) em spike separado.

**Rationale**: Código atual (`pzem_try_read_at_addr`) já lê bloco fixo; ganho real pode vir de **menos retries**, **baud 19200** (se PZEM suportar) ou **amostragem adaptativa** (parar cedo se estável).

**Alternatives considered**:

- Biblioteca Arduino PZEM completa — rejeitado (já temos Modbus enxuto)
- Amostra única para veredito — rejeitado para produção (ruído/inrush)

---

## R3 — Dual-core

**Decision**: Pinagem opcional via Kconfig: `CONFIG_TEST_TASK_CORE=0`, `CONFIG_NETWORK_TASK_CORE=1`.

**Rationale**: ESP-IDF já separa Wi-Fi stack; benefício precisa ser **medido**. Risco: mutex batch/PZEM UART se mal implementado.

**Alternatives considered**: FreeRTOS priority only — manter como baseline no bench.

---

## R4 — Atuador de refugo

**Decision**: Novo componente `line_actuator` com:

- `GPIO_REJECT` (Kconfig, default NC)
- `actuator_on_approved()` / `actuator_on_rejected()` — pulso configurável (ms)
- Estado seguro: ambos off em `HARDWARE_FAULT`

**Rationale**: Relé existente (`GPIO_RELAY`) energiza **carga/sirene**, não ejeção de peça.

**Alternatives considered**:

- Reusar mesmo relé — rejeitado (funções distintas)
- Pistão pneumático via PLC externo — fora de escopo firmware; expor GPIO seco

---

## R5 — Configuração Flutter/Firebase

**Decision**: Manter `SET_BATCH` como fonte de limites por lote; **não** introduzir `fabrica/config` nesta feature sem US explícita.

**Rationale**: Limites já persistem em NVS via `batch_storage`; app já envia no início do lote. Config mid-lote é melhoria P3.

**Alternatives considered**: Push Firebase → bridge MQTT contínuo — adiar (complexidade ACL + race com teste).

---

## R6 — Política de potência (média vs máximo)

**Decision**: Teste de produção mantém **média** no ciclo; calibração usa **máximo** (v1.7.7). Unificar só com estudo de falsos positivos.

**Rationale**: Pico transitório reprovaria peças boas; média integra inrush descartado (`INRUSH_DISCARD_MS`).

---

## R7 — Latência alvo realista

**Decision**: Meta: GPIO em &lt; 50 ms **após** última amostra do ciclo; ciclo mínimo ainda ≥ 1 s (config `tempo_teste_sec`).

**Rationale**: PZEM + integração física da sirene exigem janela; "milissegundos totais" só com single-shot após estabilização.
