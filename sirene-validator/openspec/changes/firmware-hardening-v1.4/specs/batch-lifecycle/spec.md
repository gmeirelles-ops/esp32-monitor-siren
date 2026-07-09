## SUPERSEDED

> **Status:** Superseded by `specs/006-batch-duplicate-sequence` (FR-006, sessão 2026-07-09).
>
> O requisito abaixo ("SET_BATCH com mesmo OP preserva aprovados") **não** se aplica mais.
> Todo `SET_BATCH` MUST zerar `aprovados`, aplicar `proximo_sequencial` do payload e limpar
> `ultimo_veredito`, mesmo reutilizando a mesma OP.

---

## MODIFIED Requirements (historical — v1.4)

### Requirement: SET_BATCH com mesmo OP preserva aprovados

~~O firmware SHALL preservar `aprovados` e `proximo_sequencial` quando `SET_BATCH` receber o mesmo `numero_op` do lote ativo~~ **REVOGADO por spec 006.**

#### Scenario: Reconfigurar limites do mesmo OP

- **WHEN** lote `2026001` tem 2 aprovados e chega `SET_BATCH` com mesmo `numero_op` e novos limites de potência
- **THEN** ~~`aprovados` permanece 2~~ **REVOGADO** — spec 006 exige reset completo da sessão

#### Scenario: Novo OP

- **WHEN** lote ativo é `2026001` e chega `SET_BATCH` com `numero_op` `2026002`
- **THEN** `aprovados` é zerado e novo lote substitui o anterior

### Requirement: Cota atingida encerra lote automaticamente

O firmware SHALL executar equivalente a `END_BATCH` após aprovação que atinja `quantidade_total`, publicando evento de lote encerrado.

#### Scenario: Última peça aprovada

- **WHEN** `quantidade_total` é 10 e a 10ª peça é aprovada
- **THEN** o firmware publica resultado do teste, depois `{"tipo":"batch","evento":"encerrado","motivo":"cota_atingida"}` e volta para `IDLE`
