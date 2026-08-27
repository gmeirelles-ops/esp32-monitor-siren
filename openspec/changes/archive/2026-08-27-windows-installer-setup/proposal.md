## Why

O pacote portátil (ZIP + `.bat`) atende testes em pendrive, mas no PC fixo do posto a TI e o operador esperam um **instalador** — atalho no Menu Iniciar, pasta em `Program Files` e desinstalação pelo Windows. Hoje isso exige extração manual e não aparece em "Adicionar ou remover programas".

## What Changes

- Script Inno Setup (`scripts/windows-installer/DipontoSireneValidator.iss`) empacotando o output de `flutter build windows --release`.
- Extensão de `scripts/build_windows_release.ps1` (ou script irmão `build_windows_installer.ps1`) para gerar `dist/DipontoSireneValidator-<versão>-setup.exe`.
- Atalho Menu Iniciar + opcional Área de trabalho; entrada em "Apps e recursos".
- CI `windows-release` publica **ZIP portátil** e **setup.exe** como artifacts.
- Documentação: quando usar installer vs pendrive; upgrade (reinstalar por cima).

## Capabilities

### New Capabilities

- `windows-installer-distribution`: instalador Windows (Inno Setup), atalhos, desinstalador e integração ao pipeline de release.

### Modified Capabilities

- `windows-portable-distribution`: CI e script de release passam a produzir também o setup (delta — artifact adicional, ZIP portátil mantido).
- `project-documentation`: `docs/PRODUCAO.md` e README com fluxo de instalação no posto.

## Impact

- `scripts/windows-installer/` — template `.iss` e assets (ícone se necessário).
- `scripts/build_windows_installer.ps1` — orquestra build Flutter + Inno Setup.
- `.github/workflows/ci.yml` — upload do `.exe` instalador.
- `docs/PRODUCAO.md`, `sirene_app/README.md`.
- Sem alteração de runtime do app, firmware ou Firebase.
- **Dependência de build:** Inno Setup 6 instalado no PC de dev ou via `choco install innosetup` no CI.
