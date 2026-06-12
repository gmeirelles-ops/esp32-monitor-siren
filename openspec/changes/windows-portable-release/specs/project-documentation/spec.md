## ADDED Requirements

### Requirement: Documentação de distribuição Windows portátil

A documentação de produção SHALL descrever como gerar o pacote portátil, copiar para pendrive, extrair no PC do posto e validar com smoke test mínimo (app abre, MQTT configurável, tela Lote visível).

#### Scenario: Checklist pendrive em PRODUCAO.md
- **WHEN** o supervisor consulta `docs/PRODUCAO.md`
- **THEN** encontra seção com comandos `build_windows_release.ps1`, estrutura do ZIP e passos pós-extração

#### Scenario: README do app referencia pendrive
- **WHEN** o desenvolvedor lê `sirene_app/README.md`
- **THEN** encontra link para script de release e limitação de build apenas em Windows/CI
