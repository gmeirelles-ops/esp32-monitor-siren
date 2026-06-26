# Diponto Sirene Validator

App Flutter companion do firmware `sirene-validator`. **Uso em produção: Windows desktop** no posto de trabalho.

## Desenvolvimento no Linux

No Linux você pode desenvolver e validar localmente, mas **não é possível gerar o `.exe` do Windows** a partir do Linux — o Flutter não faz cross-compile para Windows.

### Windows: caminho com acento (OneDrive / Área de Trabalho)

Se o repositório estiver em `OneDrive\Área de Trabalho\...`, **Flutter quebra** no Windows:

| Comando | Sintoma |
|---------|---------|
| `dart run build_runner` | `package_config.json did not contain its own root package` |
| `flutter build windows` | `Unable to read file: ...\?rea de Trabalho\...` |

**Solução recomendada:** clone ou mova o projeto para um caminho ASCII, ex.: `C:\dev\esp32-monitor-siren`.

**Alternativa rápida (sem mover):**

```powershell
subst S: "C:\Users\SEU_USUARIO\OneDrive\Área de Trabalho\esp32-monitor-siren"
cd S:\sirene_app
flutter clean
flutter pub get
dart run build_runner build
flutter run -d windows
```

Ou use o script auxiliar na raiz do repo:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 run -d windows
powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 test
powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 build windows --release

# Atualizar dist/ (ZIP portátil) — use sempre que mudar o app para produção
powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 dist
```

### Atualizar a pasta `dist/`

A pasta `dist/` na **raiz do repositório** não é versionada no Git. Ela é gerada pelos scripts de release. Sempre que você alterar o app e quiser distribuir no posto ou pendrive:

| Objetivo | Comando |
|----------|---------|
| Build + ZIP portátil em `dist/` | `scripts\flutter_dev.ps1 dist` ou `scripts\build_windows_release.ps1` |
| Só reempacotar (já rodou `flutter build windows --release`) | `scripts\flutter_dev.ps1 dist-only` ou `scripts\sync_dist.ps1` |
| ZIP + instalador `.exe` | `scripts\build_windows_all.ps1` |

Antes de gerar `dist/`, atualize a versão em `pubspec.yaml` (`version: x.y.z+build`). O nome do ZIP usa esse número.

Saída típica:

```
dist/DipontoSireneValidator-1.0.0-win64/
dist/DipontoSireneValidator-1.0.0-win64.zip
dist/DipontoSireneValidator-1.0.0-setup.exe   # se rodou build_windows_all
```

Abra o projeto no Cursor/VS Code a partir de `S:\` (File → Open Folder) para o IDE usar o mesmo caminho.

### O que fazer no Linux

```bash
cd sirene_app
flutter pub get
dart run build_runner build

# Testes e análise (sempre)
flutter analyze
flutter test

# Rodar UI localmente (Linux desktop — comportamento similar ao Windows)
flutter run -d linux
```

O target Linux usa o mesmo layout desktop (`NavigationRail`) e o mesmo fluxo de provisionamento (portal no navegador), então serve bem para testar MQTT, lote, seriais e etiquetas/gravação laser durante o desenvolvimento.

### Marcação de serial (Etiquetas vs Laser)

| Modo | Hardware | Configuração |
|------|----------|--------------|
| **Etiquetas (Zebra)** | ZT230 USB ou rede | Buffer ZPL múltiplos de 3 |
| **Gravação laser (Diatu)** | Diaotu B3 + DiatuCAD1 | Servidor TCP no app; laser pede serial via F2 |

Documentação laser: [`docs/laser-reference/`](../docs/laser-reference/README.md)

### O que NÃO funciona no Linux

| Ação | Linux | Windows |
|------|-------|---------|
| `flutter build windows` | Não | Sim |
| Gerar `.exe` instalável | Não | Sim |
| Abrir `ms-settings:network-wifi` | Não | Sim |

## Build para Windows (posto)

Pré-requisitos no Windows:

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows)
- Visual Studio 2022 com workload **"Desktop development with C++"**
- [Inno Setup 6](https://jrsoftware.org/isdl.php) (só para o instalador)

Na **raiz do monorepo**:

```powershell
# Instalador (PC fixo do posto)
powershell -ExecutionPolicy Bypass -File scripts\build_windows_installer.ps1

# ZIP portátil (pendrive)
powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1

# Ambos
powershell -ExecutionPolicy Bypass -File scripts\build_windows_all.ps1
```

No Linux, o script `scripts/build_windows_release.sh` apenas orienta — não gera `.exe`.

### Artefatos gerados

**Instalador** — `dist/DipontoSireneValidator-<versão>-setup.exe`

**Pacote portátil** — `dist/DipontoSireneValidator-<versão>-win64.zip`:

```
dist/DipontoSireneValidator-<versão>-win64/
├── LEIA-ME.txt
├── Iniciar Diponto Sirene Validator.bat
└── app/
    ├── sirene_app.exe
    ├── flutter_windows.dll
    └── data/
```

### Build manual (sem script)

```bash
cd sirene_app
flutter pub get
dart run build_runner build
flutter build windows --release
```

Saída em `build/windows/x64/runner/Release/` — copie a pasta inteira (não só o `.exe`).

## Configuração no posto (Windows)

1. PC na mesma rede do broker MQTT (padrão `192.168.51.87:1883`)
2. **Configurações** → host/porta do broker e IP da impressora Zebra (`9100`)
3. **Atualizar firmware** → OTA (rede) ou USB (cabo COM) — ver `docs/GUIA_COMPLETO.md` §11
4. Provisionamento ESP32: Wi-Fi `SireneValidator` → portal `http://192.168.4.1` no navegador
5. **Produtos** → cadastre cada SKU com autocalibração (peça padrão na bancada, tolerância 10%)
6. **Lote** → selecione produto cadastrado (limites preenchidos automaticamente)

### Atualização de firmware (resumo)

| Método | Onde no app | Requisitos |
|--------|-------------|------------|
| **OTA rede** | Configurações → Atualizar firmware → aba OTA | `.bin`, bancada online, mesma LAN |
| **USB cabo** | Mesma tela → aba USB | Windows, porta COM, driver CP210x/CH340 |
| **Campanha** | Configurações → Administração | Várias bancadas + um `.bin` |

USB: empacote `esptool.exe` com `scripts/bundle_esptool_windows.ps1` ou instale `pip install esptool`.

Checklist completo: [docs/PRODUCAO.md](../docs/PRODUCAO.md)

## CI — artifacts Windows (sem máquina local)

1. Abra [Actions](../../actions/workflows/ci.yml) no GitHub
2. **Run workflow** (disparo manual)
3. Baixe os artifacts do job *Windows release (ZIP + installer)*:
   - **DipontoSireneValidator-win64** — ZIP portátil
   - **DipontoSireneValidator-setup** — instalador `.exe`
4. Instale o setup ou extraia o ZIP no pendrive e execute o `.bat`
