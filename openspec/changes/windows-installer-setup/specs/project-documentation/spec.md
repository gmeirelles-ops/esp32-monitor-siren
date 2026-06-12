## ADDED Requirements

### Requirement: Documentação de instalação Windows

A documentação de produção SHALL descrever quando usar instalador (`setup.exe`) vs pacote portátil (ZIP), passos do wizard e smoke test após instalação (app abre, MQTT configurável, tela Lote).

#### Scenario: Seção instalador em PRODUCAO.md
- **WHEN** o supervisor consulta `docs/PRODUCAO.md`
- **THEN** encontra fluxo de instalação fixa no PC e distinção pendrive vs setup

#### Scenario: README referencia setup
- **WHEN** o desenvolvedor lê `sirene_app/README.md`
- **THEN** encontra comando `build_windows_installer.ps1` e pré-requisito Inno Setup 6
