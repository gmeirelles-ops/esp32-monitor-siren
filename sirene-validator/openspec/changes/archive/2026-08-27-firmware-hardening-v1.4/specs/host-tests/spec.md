## ADDED Requirements

### Requirement: Testes host cobrem validação de batch

O firmware SHALL incluir testes host em `host_tests/` para validação de campos `SET_BATCH` via funções em `pure_logic` (sem dependência ESP-IDF).

#### Scenario: CI executa novos testes

- **WHEN** `./scripts/run_host_tests.sh` é executado
- **THEN** casos de potência invertida, `id_produto` inválido e cópia segura de strings passam ou falham de forma determinística
