## Why

O repositório já tem 55 testes Flutter e host tests do firmware (`sirene-validator/host_tests`), mas nada impede regressões — não há pipeline automatizado nem verificação em PR. Várias changes arquivadas citam CI como escopo futuro; com 16 features entregues em dois dias, é hora de proteger o que foi construído.

## What Changes

- Workflow GitHub Actions na raiz: `flutter test` (sirene_app), `ctest` (host_tests), lint opcional.
- Job separado ou condicional para build IDF (`idf.py build`) quando ESP-IDF estiver disponível no runner.
- Badge de status no README (após `project-docs-and-gitignore`).
- Falha de CI bloqueia merge (configuração recomendada no repositório remoto).

## Capabilities

### New Capabilities

- `ci-pipeline`: verificação automatizada de testes e build em cada push/PR

### Modified Capabilities

_(nenhuma — infraestrutura de desenvolvimento, sem mudança de comportamento do produto)_

## Impact

- **Novo**: `.github/workflows/ci.yml`
- **Scripts**: possível `scripts/run_host_tests.sh` para padronizar execução local e no CI
- **Sem impacto** em firmware em campo nem app Windows em produção
