## 1. Workflow GitHub Actions

- [x] 1.1 Criar `.github/workflows/ci.yml` com job `flutter-test` (Ubuntu, Flutter stable, `flutter pub get`, `build_runner` se necessário, `flutter test`)
- [x] 1.2 Adicionar job `firmware-host-tests` (cmake + ctest em `host_tests`)

## 2. Script local

- [x] 2.1 Criar `scripts/ci_local.sh` espelhando os jobs
- [x] 2.2 Tornar executável e documentar no README

## 3. IDF build (opcional v1)

- [x] 3.1 Adicionar job `firmware-idf-build` com `workflow_dispatch` ou `continue-on-error: true`
- [x] 3.2 Documentar limitação no design/README

## 4. Verificação

- [ ] 4.1 Abrir PR de teste e confirmar jobs verdes
- [x] 4.2 Recomendar branch protection no repositório remoto
