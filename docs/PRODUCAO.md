# Checklist de Produção — Diponto Sirene Validator

Guia para colocar firmware v1.3.0 + app Flutter em operação no posto.

## 1. Infraestrutura de rede

- [ ] Broker Mosquitto na LAN (ex.: `192.168.51.87:1883` — IP do servidor de fábrica)
- [ ] Wi-Fi industrial estável na área da linha
- [ ] PC Windows no posto com acesso à rede MQTT e à impressora Zebra

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
5. Confirme nos logs: `device_id=... firmware=1.3.0` e `broker mqtt://... (NVS|fallback)`

### Smoke test MQTT

```bash
BROKER=192.168.51.87 DEVICE_ID=<mac_hex> ./scripts/bench_mqtt_telemetry.sh
BROKER=192.168.51.87 DEVICE_ID=<mac_hex> ./scripts/bench_calibration.sh
```

## 3. App Flutter (Windows)

### Pendrive / distribuição portátil (recomendado)

Gera ZIP pronto para copiar no pendrive e testar no posto:

**No Windows (dev):**
```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1
```

**Sem PC Windows (GitHub Actions):**
1. GitHub → **Actions** → workflow **CI** → **Run workflow**
2. Ao concluir, baixe o artifact **DipontoSireneValidator-win64.zip**
3. Copie o ZIP para o pendrive

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

> Dados SQLite ficam no perfil do usuário Windows (`%APPDATA%`), não no pendrive.

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
- Impressora Zebra (IP + porta 9100)

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

1. **Lote** → selecione dispositivo + produto cadastrado
2. Informe OP, ano, quantidade e sequencial → **SET_BATCH**
3. Operador pressiona **botão físico** para cada teste
4. Aprovações geram serial e buffer de etiquetas (múltiplos de 3)
5. **Encerrar lote** ao atingir a meta

## 6. Atualizações

- **OTA:** seção Admin → URL do `.bin` servido em HTTP na LAN
- **Recalibração:** Produtos → editar SKU → Recalibrar peça padrão

## 7. Validação ponta a ponta (bancada)

- [ ] Cadastro de produto com autocalibração
- [ ] SET_BATCH a partir do produto
- [ ] Teste aprovado → serial ITF 2 de 5
- [ ] Impressão Zebra (3 etiquetas)
- [ ] Teste reprovado → sequencial não consumido
- [ ] Reboot com lote ativo → retomada correta
- [ ] Offline → fila MQTT do ESP32 sincroniza ao reconectar
- [ ] (Opcional) Firestore sync → documento em `test_results` após teste com sync habilitado

### Smoke app (reatividade e sync)

- [ ] Badge MQTT visível em Etiquetas/Painel (não só Dispositivos)
- [ ] Painel atualiza métricas após novo teste sem trocar de aba
- [ ] Buffer de etiquetas atualiza ao aprovar sirene
- [ ] Configurações → falha permanente na fila → **Tentar novamente** após corrigir rede/login

## Referências

- [GUIA_COMPLETO.md](../sirene-validator/docs/GUIA_COMPLETO.md) — firmware e MQTT
- [TESTING.md](../sirene-validator/docs/TESTING.md) — plano de testes de bancada
- [sirene_app/README.md](../sirene_app/README.md) — build Windows
