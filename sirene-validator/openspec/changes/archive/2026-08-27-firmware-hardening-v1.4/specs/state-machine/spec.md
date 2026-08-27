## MODIFIED Requirements

### Requirement: Regras de transição delegam a pure_logic

O firmware SHALL implementar `state_machine_can_*` chamando as funções equivalentes em `pure_logic`, mapeando `app_state_t` para `pure_state_t`.

#### Scenario: Paridade com testes host

- **WHEN** `pure_fsm_can_start_test` retorna false para estado equivalente a `HARDWARE_FAULT`
- **THEN** `state_machine_can_start_test` também retorna false nesse estado
