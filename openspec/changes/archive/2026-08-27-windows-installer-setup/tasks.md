## 1. Refatoração build

- [ ] 1.1 Extrair funções compartilhadas (`Get-AppVersion`, build Flutter) para `scripts/windows_build_common.ps1`
- [ ] 1.2 Atualizar `build_windows_release.ps1` para usar módulo comum

## 2. Inno Setup

- [ ] 2.1 Criar `scripts/windows-installer/DipontoSireneValidator.iss` (PT-BR, ícone, Program Files, atalhos)
- [ ] 2.2 Criar `scripts/build_windows_installer.ps1` (build Flutter + ISCC + saída em `dist/`)

## 3. CI

- [ ] 3.1 Instalar Inno Setup no job `windows-release` (`choco install innosetup`)
- [ ] 3.2 Gerar ZIP + setup no mesmo workflow; upload de dois artifacts

## 4. Documentação

- [ ] 4.1 Seção "Instalação no PC do posto" em `docs/PRODUCAO.md` (setup vs pendrive)
- [ ] 4.2 Atualizar `sirene_app/README.md` e `README.md` raiz

## 5. Verificação

- [ ] 5.1 Smoke: instalar setup no Windows, atalho Iniciar abre app na tela Lote
- [ ] 5.2 Smoke: reinstalar sobre versão anterior sem perder SQLite em `%APPDATA%`
- [ ] 5.3 Confirmar desinstalador remove arquivos de Program Files
