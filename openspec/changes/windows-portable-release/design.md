## Context

O app `sirene_app` já suporta `flutter build windows --release`, gerando `build/windows/x64/runner/Release/` com `sirene_app.exe`, DLLs e pasta `data/`. A documentação descreve o build manual, mas não há script nem artefato único para pendrive.

**Restrições:**
- Flutter **não** cross-compila Windows a partir de Linux — o `.exe` deve ser gerado em máquina Windows ou CI `windows-latest`.
- App portátil: copiar pasta inteira `Release/` (não só o `.exe`).
- Firebase/sync opcional — build de pendrive pode usar `firebase_options.dart` já commitado ou build sem nuvem.
- Posto atual: Windows 10/11 x64.

## Goals / Non-Goals

**Goals:**
- Um comando (`.\scripts\build_windows_release.ps1`) produz pasta + ZIP prontos para pendrive.
- Launcher `.bat` para duplo clique sem linha de comando.
- `LEIA-ME.txt` em português com pré-requisitos e smoke test.
- CI publica ZIP como artifact em `workflow_dispatch` (e opcionalmente em tag `app-v*`).
- Documentação alinhada em `docs/PRODUCAO.md` e `sirene_app/README.md`.

**Non-Goals:**
- Instalador MSI/MSIX ou auto-update.
- Assinatura de código (Authenticode) — fase 2.
- Incluir broker Mosquitto ou firmware no mesmo pendrive.
- Build Windows no runner Linux do CI principal.

## Decisions

### 1. Formato de distribuição: pasta portátil + ZIP

**Decisão:** estrutura empacotada:

```
DipontoSireneValidator-<versão>-win64/
├── LEIA-ME.txt
├── Iniciar Diponto Sirene Validator.bat
└── app/
    ├── sirene_app.exe
    ├── flutter_windows.dll
    └── data/
```

**Alternativa:** Inno Setup installer — mais fricção para teste rápido em pendrive.

### 2. Script primário PowerShell

**Decisão:** `scripts/build_windows_release.ps1` na raiz do monorepo:
1. Valida `flutter` no PATH e plataforma Windows.
2. `cd sirene_app` → `flutter pub get` → `dart run build_runner build` → `flutter build windows --release`.
3. Lê versão de `pubspec.yaml` (`version:`).
4. Monta `dist/DipontoSireneValidator-<ver>-win64/`.
5. Gera ZIP em `dist/`.

**Alternativa:** só documentar comandos — erro humano frequente ao esquecer `data/`.

### 3. Espelho `.sh` para Linux (fail-fast)

**Decisão:** `scripts/build_windows_release.sh` imprime mensagem clara e sai com código 1 no Linux, apontando para Windows ou CI.

### 4. CI Windows release

**Decisão:** job `windows-release` em `.github/workflows/ci.yml` (ou `release-windows.yml`):
- `runs-on: windows-latest`
- `if: github.event_name == 'workflow_dispatch'` (evita custo em todo PR)
- Executa o script PowerShell
- Upload artifact `DipontoSireneValidator-*-win64.zip`

**Alternativa:** job em todo push — custo e tempo altos (~10–15 min).

### 5. Nome do executável e branding

**Decisão:** manter `sirene_app.exe` internamente; launcher `.bat` com nome amigável "Iniciar Diponto Sirene Validator.bat". Opcional: ajustar `ProductName` em `Runner.rc` para "Diponto Sirene Validator" (título da janela).

### 6. Dados persistentes no pendrive

**Decisão:** SQLite e SharedPreferences ficam no perfil do usuário Windows (`%APPDATA%`), não no pendrive — comportamento padrão Flutter. `LEIA-ME` documenta isso (dados não viajam com o pendrive).

## Risks / Trade-offs

- **[SmartScreen bloqueia .exe não assinado]** → documentar "Executar mesmo assim"; assinatura em change futura.
- **[VC++ runtime ausente]** → `LEIA-ME` lista link Microsoft Visual C++ Redistributable x64.
- **[Antivírus no pendrive]** → ZIP pelo CI/GitHub pode ser mais confiável que cópia NTFS direta.
- **[Build sem flutterfire]** → sync nuvem pode falhar até `flutterfire configure`; modo local OK.

## Migration Plan

1. Implementar script + docs.
2. Rodar build em máquina Windows ou `workflow_dispatch` no GitHub.
3. Copiar ZIP para pendrive; extrair; duplo clique no `.bat`.
4. Configurar MQTT/impressora; smoke conforme `docs/PRODUCAO.md`.

## Open Questions

- Publicar release no GitHub Releases automaticamente em tag, ou só artifact do workflow?
- Renomear `sirene_app.exe` → `DipontoSireneValidator.exe` (quebra atalhos existentes)?
