# Implementation Plan: 004-local-line-actuator

**Branch**: `004-local-line-actuator`  
**Spec**: [spec.md](./spec.md)

## Summary

Formalizar e estender a arquitetura **edge-first** que o projeto já possui em grande parte: veredito local no ESP32, MQTT assíncrono, app como painel. Entregas novas: **atuador de refugo**, **otimização PZEM**, **pinagem dual-core**, contratos e validação de latência.

## Technical Context

| Item | Valor |
|------|--------|
| Firmware | ESP-IDF 5.5, `sirene-validator` ≥ 1.7.7 |
| App | Flutter `sirene_app` — confia em `veredito` MQTT |
| Sensor | PZEM-004T Modbus RTU 9600 bps |
| Atuadores hoje | `GPIO_RELAY` (carga), LED feedback, OLED |
| Atuadores propostos | Segundo GPIO: relé refugo / pistão / stack light |
| Estado atual veredito | `batch_cmd_run_test_cycle` → `pure_verdict_approved` local → LED → `publish_test_result` |
| Gap principal | Sem ejeção física; ciclo inteiro (~5 s+); rede na mesma task loop; leitura Modbus completa |

## Constitution Check

| Princípio | Status |
|-----------|--------|
| Testes host (`pure_logic`, FSM) | ✓ Manter `pure_verdict_*` testável sem hardware |
| Contratos MQTT documentados | ✓ Estender `contracts/` sem quebrar `tipo:teste` |
| Bench físico documentado | ✓ quickstart com MQTT down |
| Simplicidade | ⚠ Dual-core só se medição provar bloqueio por Wi-Fi |

**Gate**: Aprovado — evolução incremental, não rewrite cloud-first.

## Phase 0 — Research ✓

Ver [research.md](./research.md): gap analysis vs proposta do usuário; decisões PZEM, dual-core, atuador.

## Phase 1 — Design ✓

- [data-model.md](./data-model.md)
- [contracts/mqtt-config-and-actuator.md](./contracts/mqtt-config-and-actuator.md)
- [quickstart.md](./quickstart.md)

## Phase 2 — Implementation (futuro — tasks.md)

| Grupo | Entregas |
|-------|----------|
| FW-A | `pzem_read_power_w_fast()` — só registrador potência |
| FW-B | `actuator_reject_pulse()` + Kconfig pin/duração |
| FW-C | `xTaskCreatePinnedToCore` para `test_worker` / rede |
| FW-D | Ordem garantida: veredito → GPIO → fila MQTT |
| App | Nenhuma mudança de veredito; opcional UI status atuador |
| Testes | Host tests latência lógica; bench PZEM ms |

## Phase 3 — Validação

[quickstart.md](./quickstart.md) — broker desligado, 10 ciclos, medir GPIO + fila.

## Resposta estratégica: é melhor que hoje?

| Aspecto | Hoje | Proposta | Veredito |
|---------|------|----------|----------|
| Quem aprova? | ESP32 local | ESP32 local | **Já alinhado** |
| Depende de MQTT? | Não para veredito | Não | **Já alinhado** |
| Papel do Flutter | Config + registro | Dashboard | **Já alinhado** |
| Atuador refugo | LED apenas | Pistão/relé | **Gap real — vale implementar** |
| Tempo de resposta | Ciclo completo (s) | ms após amostra | **Otimizar PZEM + duração; não instantâneo sem janela** |
| Dual-core | Não pinado | Core 0 teste | **Vale se bench mostrar interferência Wi-Fi** |
| Config em tempo real | `SET_BATCH` no início do lote | `fabrica/config` contínuo | **Melhoria incremental** |

**Conclusão**: A direção arquitetural é **correta e já é em grande parte a do Diponto Sirene**. O ganho industrial vem de **hardware de separação**, **ciclo mais curto** e **isolação rede/teste** — não de mover o cérebro do Firebase para o ESP32 (isso já está no ESP32).
