## Context

- **App:** `sirene_app` — Flutter Windows desktop, Riverpod, `mqtt_client`
- **Firmware:** `sirene-validator` v1.4.2 — OTA via `OTA_UPDATE` + `esp_https_ota`
- **Já existe:** `sendOtaUpdate`, `sendOtaCampaign`, `otaStreamProvider`, `AdminScreen` com URL manual
- **Dor do usuário:** Python ausente, URL manual, MQTT Explorer, cópia de `.bin` entre ambientes

## Goals / Non-Goals

**Goals:**

- Operador atualiza firmware em **≤ 3 cliques** (OTA ou USB)
- OTA sem ferramentas externas (Python, MQTT Explorer)
- USB sem ESP-IDF instalado no PC do posto
- Feedback visual: início / progresso / sucesso / falha / versão confirmada

**Non-Goals:**

- Flash wireless sem HTTP (MQTT binary stream)
- Linux/macOS USB flash na v1
- CI que publica `.bin` automaticamente para o app

## Decisions

### 1. OTA Assist — servidor HTTP embutido no Flutter

```
[Operador] → escolhe .bin → [App inicia shelf :8080]
          → detecta IP LAN (ex. 192.168.51.70)
          → URL = http://{ip}:{port}/firmware.bin
          → MQTT OTA_UPDATE → ESP32 baixa → status tipo:ota → heartbeat nova versão
```

**Pacotes:** `shelf`, `shelf_io`, reutilizar `file_selector`.

**Detecção de IP:** `NetworkInterface.list()` — preferir IPv4 não-loopback na mesma faixa do broker MQTT configurado.

**Porta:** padrão `8080`, configurável; verificar se porta está livre antes de iniciar.

**Firewall:** app exibe aviso se teste local `http://127.0.0.1:port/firmware.bin` falhar.

**Nome do arquivo servido:** cópia temporária com nome fixo `sirene-validator.bin` em `%TEMP%` para URL estável.

### 2. USB Flash — esptool empacotado (Windows)

```
[Operador] → escolhe COMx + .bin → [App executa esptool.exe]
          → log na UI → sucesso / erro
```

**Dependência:** `flutter_libserialport` para listar COM.

**Esptool:** binário standalone em `sirene_app/tools/windows/esptool.exe` (PyInstaller ou release oficial Espressif). Script `bundle_esptool_windows.ps1` documentado no repo.

**Offsets** (ESP32 4MB, layout atual):

| Imagem | Offset | Quando usar |
|--------|--------|-------------|
| `bootloader.bin` | `0x1000` | Flash completo |
| `partition-table.bin` | `0x8000` | Flash completo |
| `ota_data_initial.bin` | `0xf000` | Flash completo |
| `sirene-validator.bin` | `0x20000` | Atualização usual |

**Modos na UI:**

| Modo | Descrição |
|------|-----------|
| **Atualizar app** | Grava só `sirene-validator.bin` @ `0x20000` (equivalente OTA por cabo) |
| **Flash completo** | Exige pacote com 4 arquivos do `build/` — para chip virgem ou migração |

**Processo:** `Process.start` com stdout/stderr streamed para widget de log; botão cancelar mata o processo.

**Pré-requisão:** driver USB-Serial (CP210x/CH340) — mensagem clara se COM não listada.

### 3. UI unificada — `FirmwareUpdateScreen`

Acessível de:

- Configurações → Administração → Atualizar firmware
- Detalhe da bancada → botão "Atualizar firmware" (pré-seleciona device)

**Abas:**

1. **Pela rede (OTA)** — device online, arquivo `.bin`, botão "Iniciar atualização"
2. **Por USB (cabo)** — porta COM, arquivo, modo app/completo

**Estados compartilhados:** `idle` → `preparing` → `uploading/flashing` → `success` / `failed`

**Validações antes de OTA:**

- Device `online` (presença MQTT)
- Estado ≠ `TESTING`
- Arquivo `.bin` > 100 KB
- Servidor HTTP responde localmente antes de enviar MQTT

### 4. Evolução do AdminScreen

- Manter campanha multi-device OTA, mas usar **mesmo serviço** `OtaAssistService`
- Campo URL manual vira "avançado" (colapsado) para URL externa/CDN

### 5. Firmware ESP32

Nenhuma mudança. Contrato MQTT permanece:

```json
{ "cmd": "OTA_UPDATE", "url": "http://..." }
```

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Firewall bloqueia porta HTTP do app | Teste local + mensagem com instrução Windows Firewall |
| esptool.exe antivírus | Documentar exceção; assinar binário em release |
| WSL vs Windows IP confuso | App roda nativo Windows — IP do `NetworkInterface` do host |
| Flash só app corrompe se layout mudou | UI avisa "use flash completo na primeira vez" |
| OTA durante teste | Firmware já rejeita; app valida estado antes de enviar |

## Open Questions

- Incluir `.bin` pré-compilado em `assets/firmware/` para update sem build? (recomendado: opcional na v1.1)
- Porta HTTP padrão 8080 conflita com outros serviços — tornar configurável em Settings
