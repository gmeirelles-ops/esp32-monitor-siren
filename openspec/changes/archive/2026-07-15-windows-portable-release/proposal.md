## Why

O posto de produção usa PC Windows, mas hoje não há um artefato pronto para copiar em pendrive e testar sem clonar o repositório nem instalar Flutter/Visual Studio. Isso atrasa validação em fábrica, troca de máquina e entrega para terceiros.

## What Changes

- Script de empacotamento Windows (`build` + cópia da pasta `Release/` + ZIP nomeado com versão).
- Atalho/launcher (`Diponto Sirene Validator.bat`) para abrir o `.exe` a partir do pendrive.
- `LEIA-ME.txt` com pré-requisitos (VC++ runtime), configuração MQTT/impressora e smoke test.
- Job CI opcional em `windows-latest` publicando artefato ZIP para download.
- Documentação atualizada (`docs/PRODUCAO.md`, `sirene_app/README.md`) com fluxo pendrive.

## Capabilities

### New Capabilities

- `windows-portable-distribution`: build release Windows, empacotamento portátil (pasta + ZIP), launcher e instruções para execução a partir de pendrive sem instalação.

### Modified Capabilities

- `project-documentation`: checklist de produção e README do app com passo a passo de cópia para pendrive e primeiro uso no Windows.

## Impact

- `scripts/` — novo `build_windows_release.ps1` (e espelho `.sh` documentando limitação Linux).
- `.github/workflows/` — job Windows release (pode estender `ci.yml` ou workflow dedicado).
- `sirene_app/windows/runner/` — metadados de versão/produto se necessário para nome do artefato.
- `docs/PRODUCAO.md`, `sirene_app/README.md`, `README.md` — instruções de distribuição.
- Sem alteração de firmware, MQTT ou regras Firestore.
