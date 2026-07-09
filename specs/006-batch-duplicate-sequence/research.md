# Research: 006-batch-duplicate-sequence

**Date**: 2026-07-09

## Decisions

### 1. Bloqueio reteste peça aprovada (FR-004)

- **Decision**: Firmware + app
- **Rationale**: O operador usa o botão físico; bloqueio só no app não impede novo ciclo.
- **Alternatives**: App-only (rejeitado), firmware-only (insuficiente para UX)

### 2. Novo lote limpo (FR-006)

- **Decision**: Reset explícito em todo `SET_BATCH`
- **Rationale**: Preservação `same_op` no firmware causou vazamento de contadores no segundo lote.
- **Alternatives**: OP sempre diferente (restritivo), filtro só no app (divergência NVS)

### 3. Fonte da verdade do sequencial (FR-005, FR-010)

- **Decision**: Firmware NVS + heartbeat
- **Rationale**: `proximo_sequencial` incrementa na NVS antes do MQTT chegar ao app.
- **Alternatives**: App/SQLite (atraso), maior valor (ambíguo)

### 4. MQTT down com bancada ativa (FR-007, FR-009)

- **Decision**: Continuar testes locais + reconciliar ao reconectar
- **Rationale**: Produção não pode parar; operador confia no OLED; app sincroniza aprovados e seriais.
- **Alternatives**: Bloquear botão sem MQTT (paralisa fábrica)

### 5. Dedupe de resultados (FR-008)

- **Decision**: `(numero_op, ts_ms)`
- **Rationale**: Alinha spec 003; `testExistsByOpAndTsMs` já existe no SQLite; evita duplicata quando sequencial diverge.
- **Alternatives**: `(op, ts_ms, sequencial)` — comportamento atual, causa gaps

## Implementation notes

- Cooldown pós-aprovação: 5000 ms default, Kconfig `CONFIG_SIRENE_POST_APPROVAL_COOLDOWN_MS`
- Watchdog app: 15 s para sair de Testando/Aguardando MQTT (spec 005 SC-004)
- Rejeição MQTT: `peca_ja_aprovada` em `/status`
