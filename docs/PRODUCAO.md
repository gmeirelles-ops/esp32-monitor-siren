# Checklist de Produção — Diponto Sirene Validator

Guia para colocar firmware **v1.8.10** + app Flutter **1.0.1** em operação no posto.

## 1. Infraestrutura de rede

- [ ] Broker Mosquitto na LAN (ex.: `192.168.51.87:1883` — IP do servidor de fábrica)
- [ ] Wi-Fi industrial estável na área da linha
- [ ] PC Windows no posto com acesso à rede MQTT e ao laser **Diatu / DiatuCAD**

## 2. Firmware (ESP32)

1. (Opcional) Ajuste o fallback de fábrica `MQTT_BROKER_URI` em `board_config.h` — usado apenas se o portal não informar broker
2. Compile:
   ```bash
   cd sirene-validator
   idf.py -B /tmp/sv_build build
   ```
3. Grave cada bancada por cabo USB (primeira vez com layout OTA):
   ```bash
   idf.py -B /tmp/sv_build -p /dev/ttyUSB0 flash
   ```
4. Provisione via portal `http://192.168.4.1` (AP `SireneValidator`):
   - Wi-Fi: SSID + senha
   - **Broker MQTT (opcional):** host + porta — se vazio, usa fallback de `board_config.h`
5. Confirme nos logs: `device_id=... firmware=1.8.10` e `broker mqtt://...` ou `wss://... (NVS|fallback)`

### Smoke test MQTT

```bash
BROKER=192.168.51.87 DEVICE_ID=<mac_hex> ./scripts/bench_mqtt_telemetry.sh
BROKER=192.168.51.87 DEVICE_ID=<mac_hex> ./scripts/bench_calibration.sh
```

## 3. App Flutter (Windows)

### Requisito de hardware (CPU)

O app usa o motor Flutter/Dart, que exige **SSE4.1** no processador. Se o PC do posto for muito antigo, o app **abre e fecha na hora** e o Visualizador de Eventos mostra:

- Código de exceção: **0xc000001d** (instrução ilegal)
- Módulo: `sirene_app.exe`

**No PC com problema**, confira o processador:

```powershell
Get-CimInstance Win32_Processor | Select-Object Name
```

Processadores **incompatíveis** (exemplos): AMD Phenom II, Intel Core 2 Duo, Atom N270/N450.  
**Compatíveis**: Intel Core i3/i5/i7 a partir da 2ª geração (2011+), AMD Ryzen, a maioria dos PCs de escritório dos últimos 12 anos.

**Solução:** usar outro PC no posto ou trocar a máquina. Não é problema de “usuário normal” do Windows nem de permissão de cadastro.

### Instalador (recomendado para PC fixo do posto)

Gera `DipontoSireneValidator-<versão>-setup.exe` (wizard em português, Menu Iniciar, desinstalador):

**No Windows (dev):**
```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows_installer.ps1
```

Pré-requisito adicional: [Inno Setup 6](https://jrsoftware.org/isdl.php) (`choco install innosetup`).

**No PC do posto:**
1. Execute o setup (SmartScreen pode alertar — app não assinado)
2. Use o atalho **Diponto Sirene Validator** no Menu Iniciar
3. Dados SQLite ficam em `Documentos\sirene_app.sqlite` (reinstalar preserva dados locais)

> **Login de operador:** toda abertura do app exige seleção de nome + PIN. A sessão não persiste entre execuções — feche e reabra para validar o fluxo no posto.

> **Setup do posto:** na primeira execução (ou após reset), o app pede para vincular **uma bancada** ao PC. A tela de Lote não permite trocar bancada — use **Configurações → Manutenção do posto**. Ano e próximo sequencial do lote são calculados automaticamente.

> **Reset geral:** em **Configurações → Manutenção do posto → Reset geral do posto**, digite `ZERAR` para apagar SQLite (`Documentos\sirene_app.sqlite`), preferências locais, vínculo de bancada e flag de Wi-Fi. Reabra o app e reconfigure login + bancada.

> **Regravar:** a busca por serial enfileira regravação laser (F2 no DiatuCAD).

> **Catálogo na nuvem:** com sync habilitado, **Baixar catálogo** traz produtos e operadores da coleção Firestore `operators/{PIN}`.

> **Sync obrigatório:** na primeira execução o assistente **Configuração da nuvem** exige login Firebase, `station_id` e habilita sync. Depois disso o sync **não pode ser desligado** em Configurações. Cada posto envia heartbeat em `stations/{station_id}` para o painel gestor monitorar postos sem dados.

> **Build Windows:** se a pasta do projeto tiver acentos (OneDrive), use o junction `C:\dev\diponto-sirene` — ver README.

### Instalação pelo USB (posto sem baixar nuvem)

Quando o PC do posto não consegue sincronizar ou baixar catálogo:

1. **No PC de configuração** (onde a nuvem funciona): abra o app → Configurações → **Baixar catálogo** → feche o app.
2. No pendrive (pasta do ZIP win64): **Exportar dados para USB.bat**
3. **No posto**: **Instalar no PC.bat** (copia app para `C:\Diponto\SireneValidator` + catálogo SQLite).

Script completo (monta pendrive + exporta):

```powershell
powershell -File scripts\preparar_usb_posto.ps1 -UsbRoot E:\ -ExportarDestePc -SemSync
```

`-SemSync` evita exigir login Firebase no posto na primeira abertura; habilite depois em Configurações.

Detalhes: `scripts\windows-portable\LEIA-ME-USB-POSTO.txt`

## 4. App gestor (escritório)

App separado **`sirene_manager_app`** — dashboard analítico para supervisores, lendo dados sincronizados no Firestore (sem MQTT).

```powershell
cd sirene_manager_app
flutter pub get
flutter run -d windows
# ou: powershell -File ..\scripts\build_manager_windows.ps1
```

- Login com conta Firebase (gestor; claim `manager` opcional via `firebase/scripts/set_manager_claim.js`)
- KPIs consolidados, saúde dos postos (`stations`), produção por OP e operador
- Consulta global de serial; export CSV em `Documentos\relatorios_gestor`
- Cloud Function `aggregateProduction` (deploy: `firebase deploy --only functions`)
- Postos precisam ter completado o **setup da nuvem** para alimentar o painel

No app **operador**: botão de lote = **INICIAR**; item **Painel** removido do menu (resumo do dia na tela Lote).

### Pendrive / distribuição portátil

Gera ZIP pronto para copiar no pendrive e testar no posto:

**No Windows (dev):**
```powershell
# Build completo + ZIP em dist/
powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1

# Ou pelo helper (usa caminho S: se houver acento na pasta)
powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 dist

# Ja compilou com flutter build windows --release? So atualiza dist/
powershell -ExecutionPolicy Bypass -File scripts\sync_dist.ps1
```

**ZIP + instalador de uma vez:**
```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows_all.ps1
```

**Sem PC Windows (GitHub Actions):**
1. GitHub → **Actions** → workflow **CI** → **Run workflow**
2. Ao concluir, baixe os artifacts:
   - **DipontoSireneValidator-win64.zip** (pendrive)
   - **DipontoSireneValidator-setup** (instalador `.exe`)
3. Copie o ZIP para o pendrive ou instale o setup no PC do posto

> **Build local falhou?** Se o projeto estiver em pasta com acentos (ex.: `Área de Trabalho` no OneDrive), o Flutter/MSBuild pode falhar. Clone ou copie o repositório para um caminho simples (ex.: `C:\dev\esp32-monitor-siren`) ou use `subst S: "C:\Users\...\esp32-monitor-siren"` e rode os scripts a partir de `S:\`.

**No PC do posto:**
1. Extraia o ZIP inteiro (mantenha a pasta `app\` junto do `.bat`)
2. Duplo clique em **Iniciar Diponto Sirene Validator.bat**
3. Leia `LEIA-ME.txt` no pacote para pré-requisitos e smoke test

Saída do script:
```
dist/DipontoSireneValidator-<versão>-win64/
├── LEIA-ME.txt
├── Iniciar Diponto Sirene Validator.bat
└── app/
    ├── sirene_app.exe
    └── data/   ← obrigatório; não copie só o .exe
```

> Dados SQLite ficam em `Documentos\sirene_app.sqlite` no perfil do usuário Windows, não no pendrive.

### Build manual (alternativa)

No PC de produção (não compila no Linux):

```bash
cd sirene_app
flutter pub get
dart run build_runner build
flutter build windows --release
```

Copie `build/windows/x64/runner/Release/` inteira para o posto.

Configure em **Configurações**:
- Broker MQTT (host + porta) — deve coincidir com o broker provisionado nos ESP32
- **Gravação laser (DiatuCAD)** — ver [`docs/laser-reference/`](laser-reference/README.md)

### Laser Diatu / DiatuCAD (marcação de serial)

Único modo de marcação física no produto: gravação laser. O app é servidor TCP; o DiatuCAD puxa o serial da fila.

1. Instale **DiatuCAD** e conecte a placa USB do laser (sair do modo demonstração)
2. Crie template com **Texto variável → TCP/IP** — ver [`docs/laser-reference/diatu-tcp.md`](laser-reference/diatu-tcp.md)
3. No app: **Configurações** → **Gravação** → porta TCP (padrão 9101) → **Salvar**
4. Checklist laser:
   - [ ] Comando TCP idêntico no app e no DiatuCAD (`TCP: Give me string`)
   - [ ] **Marca de controlo TCP** desativada no Diaotu (evita conflito de porta)
   - [ ] **Testar gravação** enfileira `0000000000`
   - [ ] **Simular DiatuCAD** no painel diagnóstico retorna `0000000000`
   - [ ] `scripts\test_laser_tcp.ps1` retorna serial (não `ERROR:*`)
   - [ ] F2 no DiatuCAD grava serial na carcaça
   - [ ] Aprovação real na bancada → serial ITF gravado via F2
5. Em falha: capturar log do painel **Diagnóstico laser** e anexar ao relatório

> Referência histórica de etiquetas Zebra (obsoleta): [`docs/label-reference/`](label-reference/README.md).

### Firebase / Firestore (opcional — nuvem)

Sincronização centralizada de testes, lotes, dispositivos e catálogo. **Não bloqueia** operação local.

1. **Console:** projeto `monitor-sirenv2-6d201` (Monitor-SirenV2), Firestore Standard (`southamerica-east1`) e Auth (e-mail/senha).
2. **Contas:** criar usuários de operador no Console (sem auto-registro no app).
3. **CLI (uma vez, na máquina de dev):**
   ```bash
   npm install -g firebase-tools   # ou npx firebase-tools@latest
   firebase login
   firebase use monitor-sirenv2-6d201
   ./scripts/setup_firebase.sh        # na raiz deste repositório (após firebase login)
   ```
4. **FlutterFire (uma vez por plataforma):**
   ```bash
   cd sirene_app
   dart pub global activate flutterfire_cli
   flutterfire configure
   flutter pub get && dart run build_runner build
   flutter build windows --release
   ```
5. **No posto:** Configurações → Nuvem → `station_id` → login → habilitar sync.

Sem `flutterfire configure`, o app funciona normalmente em modo só-local.

## 4. Cadastro de produtos (primeira vez por SKU)

Para cada modelo de sirene:

1. Abra **Produtos** → **Novo produto**
2. Informe ID (3 dígitos), nome e tolerância (padrão **10%**)
3. Posicione **peça padrão** na bancada (dispositivo em `IDLE`)
4. Clique **Medir peça padrão** — acompanhe leituras ao vivo
5. Confirme `potencia_ref`, `min` e `max` calculados → **Cadastrar**

## 5. Operação diária

1. **Login** → selecione operador e informe PIN (obrigatório em toda abertura)
2. **Lote** → selecione dispositivo + produto cadastrado
3. Informe OP, ano, quantidade e sequencial → **SET_BATCH**
4. Operador pressiona **botão físico** para cada teste
5. Aprovações geram serial ITF e enfileiram gravação laser (F2 no DiatuCAD)
6. **Encerrar lote** ao atingir a meta

**Gestor — Painel:** use **Exportar** para PDF/XML ou **CSV resumo** / **CSV testes** (Excel PT-BR, UTF-8). O CSV respeita os filtros de período/OP/produto/bancada da tela.

## 6. Atualizações

### OTA pela rede (recomendado)

1. No app: **Admin → Abrir Atualizar firmware** (ou campanha OTA para várias bancadas)
2. Aba **Pela rede (OTA)** → escolha bancada + arquivo `sirene-validator.bin`
3. Confira o checklist (mesma LAN, firewall, bancada online) → **Iniciar atualização OTA**
4. O app sobe HTTP local (Dart; Python só se necessário), envia `OTA_UPDATE` e aguarda status

Fallback manual (sem app): `cd build && python3 -m http.server 8080` + MQTT Explorer — ver guia do firmware.

### Flash USB (primeira gravação / recovery)

1. No app Windows: **Atualizar firmware → Por USB (cabo)**
2. Ou no PC de build: `idf.py -B /tmp/sv_build -p COMx flash`

### Recalibração

- Produtos → editar SKU → Recalibrar peça padrão

## 7. Validação ponta a ponta (bancada)

- [ ] Cadastro de produto com autocalibração
- [ ] SET_BATCH a partir do produto
- [ ] Teste aprovado → serial ITF 2 de 5
- [ ] Fila laser → F2 grava serial na carcaça
- [ ] Teste reprovado → sequencial não consumido
- [ ] Reboot com lote ativo → retomada correta
- [ ] Offline → fila MQTT do ESP32 sincroniza ao reconectar
- [ ] (Opcional) Firestore sync → após teste aprovado: `test_results/{op}/seriais/{serial}`; reprovado: `test_results/{op}/reprovadas/{seq}`

### Smoke app (reatividade e sync)

- [ ] Badge MQTT visível em Gravação/Painel (não só Dispositivos)
- [ ] Painel atualiza métricas após novo teste sem trocar de aba
- [ ] Painel → Exportar → **CSV resumo** / **CSV testes** abre no Excel com acentos
- [ ] Fila de gravação atualiza ao aprovar sirene
- [ ] Configurações → falha permanente na fila → **Tentar novamente** após corrigir rede/login

## 8. Backup e troca de PC

O histórico do posto (SQLite) deve ser respaldado com frequência — a nuvem é opcional e a SyncQueue pode estar vazia ou atrasada.

### Backup semanal (recomendado)

1. No app: **Configurações → Manutenção → Fazer backup**
2. Salve o ZIP (`sirene_backup_YYYYMMDD_HHMMSS.zip`) em pasta de rede ou pendrive do posto
3. O ZIP contém: `sirene_app.sqlite`, `manifest.json` (schema/station/app) e `prefs.json` (MQTT, laser, station)

### Restore / máquina nova

1. Instale o app Windows (mesma versão ou **mais nova** que a do backup)
2. **Configurações → Manutenção → Restaurar backup** → escolha o ZIP
3. Se houver sync pendente, o app avisa; digite `RESTAURAR` para confirmar
4. Feche e reabra o aplicativo; confira lotes/seriais e Configurações (MQTT/laser)
5. Backup com schema **maior** que o app é rejeitado — atualize o `.exe` antes

> Faça backup **antes** de um reset geral do posto.

## Referências

- [GUIA_COMPLETO.md](../sirene-validator/docs/GUIA_COMPLETO.md) — firmware e MQTT
- [TESTING.md](../sirene-validator/docs/TESTING.md) — plano de testes de bancada
- [sirene_app/README.md](../sirene_app/README.md) — build Windows
