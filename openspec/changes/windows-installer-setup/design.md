## Context

A change `windows-portable-release` entrega ZIP + launcher para pendrive via `build_windows_release.ps1` e job CI `windows-release`. O app Flutter gera `sirene_app/build/windows/x64/runner/Release/` com `.exe`, DLLs e `data/`.

**Posto de produção:** PC Windows 10/11 x64 fixo; operação local via SQLite em `%APPDATA%` (dados **não** migram automaticamente entre instalações — comportamento atual).

## Goals / Non-Goals

**Goals:**
- `DipontoSireneValidator-<versão>-setup.exe` instalável com wizard em português (Inno Setup).
- Instalação padrão em `{autopf}\Diponto\Sirene Validator\` com todos os arquivos de `Release/`.
- Atalho **Menu Iniciar**; checkbox opcional **Área de trabalho** no wizard.
- Desinstalador registrado no Windows; upgrade = executar setup novo (mesma versão ou superior).
- Reutilizar versão de `pubspec.yaml` e pipeline CI existente.

**Non-Goals:**
- MSIX / Microsoft Store.
- Assinatura Authenticode (SmartScreen continuará alertando — documentar).
- Auto-update em background.
- Instalar Mosquitto, drivers ou VC++ redist bundled (apenas link no LEIA-ME).
- Migrar dados SQLite entre versões (fora de escopo).

## Decisions

### 1. Inno Setup 6

**Decisão:** Inno Setup — gratuito, script `.iss` versionável, amplamente usado para apps desktop.

**Alternativa MSIX:** melhor para Intune, mais complexo para v1.

### 2. Layout de instalação

```
C:\Program Files\Diponto\Sirene Validator\
├── sirene_app.exe
├── flutter_windows.dll
├── data\
└── LEIA-ME.txt
```

**Decisão:** instalar conteúdo de `Release/` diretamente (sem subpasta `app/` — diferente do ZIP portátil).

### 3. Script de build

**Decisão:** `scripts/build_windows_installer.ps1`:
1. Chama lógica compartilhada de build Flutter (extrair funções de `build_windows_release.ps1` para `scripts/windows_build_common.ps1` ou invocar release parcial).
2. Substitui `{{VERSION}}` no `.iss` ou passa `/DMyAppVersion=...` ao compilador.
3. Executa `ISCC.exe` (Inno Setup Compiler).
4. Saída: `dist/DipontoSireneValidator-<ver>-setup.exe`.

**Alternativa:** só `.iss` manual — erro humano ao esquecer rebuild.

### 4. CI

**Decisão:** estender job `windows-release`:
```yaml
- choco install innosetup -y
- ./scripts/build_windows_installer.ps1
- upload artifact setup.exe + zip (do script portátil existente)
```

Ou um único `build_windows_all.ps1` que gera ambos.

### 5. Identidade visual

**Decisão:** reutilizar `sirene_app/windows/runner/resources/app_icon.ico` no setup e atalhos. Nome exibido: **Diponto Sirene Validator**.

### 6. Coexistência portátil + installer

**Decisão:** manter ZIP portátil para pendrive/teste; installer para deploy fixo. Documentar claramente os dois fluxos.

## Risks / Trade-offs

- **[Inno Setup ausente no dev]** → documentar install; CI usa `choco install innosetup`.
- **[SmartScreen]** → LEIA-ME + doc; assinatura em change futura.
- **[Reinstalar não apaga SQLite]** → upgrade preserva dados em `%APPDATA%` (desejável); doc explica.
- **[Dois artefatos para manter]** → script unificado `build_windows_all.ps1` reduz duplicação.

## Migration Plan

1. Implementar `.iss` + scripts.
2. Gerar setup via CI ou Windows local.
3. TI instala no PC do posto; operador usa atalho Iniciar.
4. Pendrive continua disponível para máquinas temporárias.

## Open Questions

- Instalação **por máquina** (all users) vs **por usuário**? (recomendado: all users / Program Files para posto compartilhado)
- Incluir VC++ Redist como prereq no wizard Inno? (recomendado: link externo v1)
