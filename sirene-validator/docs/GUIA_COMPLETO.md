# Guia Completo — Sirene Validator (Firmware ESP32)

Documentação detalhada do firmware `sirene-validator` v**1.2.0**, sua integração com MQTT, o app Flutter companion e a arquitetura prevista com Firebase.

---

## Índice

1. [Visão geral](#1-visão-geral)
2. [Arquitetura do sistema](#2-arquitetura-do-sistema)
3. [Hardware e pinagem](#3-hardware-e-pinagem)
4. [Estrutura do firmware](#4-estrutura-do-firmware)
5. [Máquina de estados (FSM)](#5-máquina-de-estados-fsm)
6. [Fluxo de teste de potência](#6-fluxo-de-teste-de-potência)
7. [Configuração MQTT](#7-configuração-mqtt)
8. [Contratos MQTT (comandos e mensagens)](#8-contratos-mqtt-comandos-e-mensagens)
9. [Provisionamento Wi-Fi](#9-provisionamento-wi-fi)
10. [Persistência offline](#10-persistência-offline)
11. [OTA (atualização remota)](#11-ota-atualização-remota)
12. [Telemetria e robustez](#12-telemetria-e-robustez)
13. [Particionamento de flash](#13-particionamento-de-flash)
14. [Compilação e gravação](#14-compilação-e-gravação)
15. [App Flutter companion](#15-app-flutter-companion)
16. [Firebase (integração prevista)](#16-firebase-integração-prevista)
17. [Rastreabilidade e etiquetas](#17-rastreabilidade-e-etiquetas)
18. [Segurança e limitações](#18-segurança-e-limitações)
19. [Testes e validação](#19-testes-e-validação)
20. [Referência rápida](#20-referência-rápida)

---

## 1. Visão geral

O **sirene-validator** é um firmware ESP32 (ESP-IDF) para a linha de produção Diponto. Ele valida a **potência elétrica** de sirenes sob teste, controla o relé que energiza a peça, mede via **PZEM-004T**, e comunica resultados em tempo real via **MQTT**.

Responsabilidades do firmware:

| Faz | Não faz |
|-----|---------|
| Medir potência e dar veredito APROVADO/REPROVADO | Calcular dígito verificador ITF 2 de 5 |
| Gerenciar sequencial do lote (só em aprovação) | Imprimir etiquetas Zebra |
| Persistir lote e fila offline | Conectar ao Firebase diretamente |
| Publicar resultados via MQTT | Configurar broker MQTT em runtime |
| Provisionar Wi-Fi via captive portal | Disparar teste remotamente (só botão físico) |

Versão atual: **1.2.0** (definida em `board_config.h`).

---

## 2. Arquitetura do sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                     LINHA DE PRODUÇÃO                           │
│                                                                 │
│  ┌──────────┐    MQTT     ┌─────────┐    TCP     ┌───────────┐  │
│  │  ESP32   │◄──────────►│ Broker  │◄─────────►│ App       │  │
│  │ sirene-  │  Wi-Fi     │Mosquitto│           │ Flutter   │  │
│  │ validator│            └─────────┘           │ (Windows) │  │
│  │          │                                  └─────┬─────┘  │
│  │ PZEM     │                                        │         │
│  │ Relé     │                                  ┌─────▼─────┐  │
│  │ Botão    │                                  │ Zebra     │  │
│  └──────────┘                                  │ ZT230     │  │
│                                                └───────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                    (fase 2 — opcional)
                              ▼
                    ┌─────────────────┐
                    │ Firebase        │
                    │ Firestore       │
                    └─────────────────┘
```

O ESP32 é um **appliance de bancada**: o operador pressiona o botão físico para cada teste. O app Flutter configura lotes, monitora resultados, gera seriais e imprime etiquetas. O Firebase entra como camada de persistência em nuvem (fase 2).

---

## 3. Hardware e pinagem

Todos os pinos são definidos em:

```
sirene-validator/components/board_config/include/board_config.h
```

### Mapa de GPIOs

| Função | GPIO | Direção | Descrição |
|--------|------|---------|-----------|
| **Relé** | `26` | Saída | Energiza a sirene sob teste. **Sempre desligado no boot.** |
| **Botão** | `27` | Entrada (pull-up) | Dispara o ciclo de teste. Debounce 50 ms. |
| **LED status** | `25` | Saída | Feedback visual (aprovado/falha). |
| **Buzzer** | `33` | Saída | Feedback sonoro (reprovado/falha). |

### UART PZEM-004T

| Parâmetro | Valor |
|-----------|-------|
| UART | `UART_NUM_2` |
| TX (ESP32 → PZEM) | GPIO `17` |
| RX (ESP32 ← PZEM) | GPIO `16` |
| Baud rate | `9600` |
| Endereço Modbus | `0xF8` |

### Ligação sugerida

```
ESP32 GPIO 17 (TX) ──► RX do PZEM-004T
ESP32 GPIO 16 (RX) ◄── TX do PZEM-004T
ESP32 GPIO 26      ──► IN do módulo relé ──► Sirene em teste
ESP32 GPIO 27      ◄── Botão (GND ao pressionar, pull-up interno)
ESP32 GPIO 25      ──► LED + resistor
ESP32 GPIO 33      ──► Buzzer
```

### Feedback local (LED/buzzer)

| Evento | Comportamento |
|--------|---------------|
| APROVADO | LED acende 300 ms |
| REPROVADO | Buzzer pisca 3× (100 ms on/off) |
| Falha hardware / fila cheia | LED + buzzer por 1 s |

### Requisitos de hardware

- ESP32 com **flash de 4 MB**
- Fonte estável para sirene + ESP32
- PZEM-004T com isolamento adequado (medição em alta tensão)

---

## 4. Estrutura do firmware

```
sirene-validator/
├── main/main.c                 # Orquestração, MQTT, worker task
├── components/
│   ├── board_config/           # Constantes (GPIO, MQTT, timing)
│   ├── device_id/              # MAC → device_id, builder de tópicos
│   ├── wifi_prov/              # Captive portal + STA
│   ├── mqtt_bridge/            # Cliente MQTT + LWT + reconexão
│   ├── state_machine/          # FSM central
│   ├── batch_storage/          # Lote ativo em NVS
│   ├── offline_queue/          # Fila FIFO em SPIFFS
│   ├── pzem/                   # Driver PZEM-004T (Modbus UART)
│   ├── relay/                  # Controle seguro do relé
│   ├── button/                 # Botão com debounce (ISR → fila)
│   ├── led_feedback/           # LED/buzzer
│   ├── telemetry/              # Heartbeat periódico
│   ├── ota_update/             # OTA via esp_https_ota
│   └── pure_logic/             # Lógica pura (testável no host)
├── partitions.csv              # Layout OTA + SPIFFS
├── sdkconfig.defaults          # Rollback, TWDT, MQTT 3.1.1
├── host_tests/                 # Testes CI sem hardware
├── scripts/                    # Scripts de bancada MQTT
└── docs/                       # Documentação
```

---

## 5. Máquina de estados (FSM)

```
PROVISIONING ──► IDLE ──► BATCH_READY ⇄ TESTING
                  │           │
                  │           ▼
                  │    HARDWARE_FAULT
                  │           │
                  ▼           ▼
            OTA_UPDATING ◄────┘
```

| Estado | Significado | Teste? | SET_BATCH? | Calibração? | OTA? |
|--------|-------------|--------|------------|-------------|------|
| `PROVISIONING` | Portal Wi-Fi ativo | Não | Não | Não | Não |
| `IDLE` | Sem lote | Não | Sim | Sim | Sim |
| `BATCH_READY` | Lote configurado | **Botão** | Sim | Não | Sim |
| `TESTING` | Medindo potência | — | Rejeitado | Rejeitado | Rejeitado |
| `HARDWARE_FAULT` | PZEM sem resposta | Bloqueado | Depende | Não | Sim |
| `OTA_UPDATING` | Baixando firmware | Bloqueado | Rejeitado | Rejeitado | — |

O estado atual aparece no heartbeat MQTT (`estado`).

---

## 6. Fluxo de teste de potência

1. App envia `SET_BATCH` via MQTT → firmware vai para `BATCH_READY`
2. Operador pressiona o **botão físico**
3. Relé liga → PZEM mede por `tempo_teste` segundos
4. Primeiros **500 ms** descartados (inrush da sirene)
5. Média calculada e comparada com `potencia_min` / `potencia_max`
6. Relé desliga → veredito publicado em MQTT
7. Se **APROVADO**: sequencial consumido e incrementado (persistido em NVS)
8. Se **REPROVADO**: sequencial permanece igual

> O teste **não pode ser disparado remotamente** — decisão de design para garantir que o operador está presente na bancada.

---

## 7. Configuração MQTT

### Onde configurar

O broker é **hardcoded em tempo de compilação**:

```c
// components/board_config/include/board_config.h
#define MQTT_BROKER_URI  "mqtt://192.168.1.100:1883"
```

Para mudar o IP do broker:

1. Edite `MQTT_BROKER_URI` no `board_config.h`
2. Recompile e grave o firmware (`idf.py flash`)
3. No app Flutter, configure o **mesmo IP** em Configurações (o app permite alterar em runtime)

### Instalar broker Mosquitto (rede de fábrica)

**Linux (servidor na rede local):**

```bash
sudo apt install mosquitto mosquitto-clients
```

Edite `/etc/mosquitto/mosquitto.conf`:

```conf
listener 1883
allow_anonymous true
```

```bash
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
```

**Windows:** instale [Mosquitto para Windows](https://mosquitto.org/download/) e habilite o serviço na porta 1883.

### Device ID

Derivado do MAC Wi-Fi STA do ESP32 (12 caracteres hex, sem dois-pontos):

```
MAC: AA:BB:CC:DD:EE:FF  →  device_id: aabbccddeeff
```

Aparece nos logs no boot:

```
I (xxx) main: device_id=aabbccddeeff firmware=1.2.0
```

### Tópicos MQTT

Padrão: `sirene/<device_id>/<suffix>`

| Tópico | Direção | QoS | Retain | Descrição |
|--------|---------|-----|--------|-----------|
| `sirene/<id>/comando` | ESP32 **sub** | 1 | — | Comandos recebidos |
| `sirene/<id>/status` | ESP32 pub | 1 | — | Resultados, rejeições, OTA |
| `sirene/<id>/calibracao` | ESP32 pub | 1 | — | Potência de referência |
| `sirene/<id>/alerta` | ESP32 pub | 1 | — | Falhas de hardware |
| `sirene/<id>/presenca` | ESP32 pub + LWT | 1 | **sim** | `online` / `offline` |
| `sirene/<id>/heartbeat` | ESP32 pub | 1 | — | Saúde a cada 30 s |

### Testar conexão manualmente

```bash
# Substituir pelo device_id real
DEVICE_ID=aabbccddeeff
BROKER=192.168.1.100

# Monitorar presença e heartbeat
mosquitto_sub -h $BROKER -v \
  -t "sirene/$DEVICE_ID/presenca" \
  -t "sirene/$DEVICE_ID/heartbeat"

# Enviar lote
mosquitto_pub -h $BROKER -q 1 \
  -t "sirene/$DEVICE_ID/comando" \
  -m '{"cmd":"SET_BATCH","numero_op":"2026001","id_produto":"123","ano":"26","tempo_teste":5,"potencia_min":18.0,"potencia_max":22.0,"quantidade_total":10,"proximo_sequencial":1}'
```

---

## 8. Contratos MQTT (comandos e mensagens)

### Comandos (publicar em `sirene/<id>/comando`)

#### SET_BATCH — Configurar lote

```json
{
  "cmd": "SET_BATCH",
  "numero_op": "2026001",
  "id_produto": "123",
  "ano": "26",
  "tempo_teste": 5,
  "potencia_min": 18.0,
  "potencia_max": 22.0,
  "quantidade_total": 10,
  "proximo_sequencial": 1
}
```

- Todos os campos são obrigatórios; validação rejeita `tempo_teste` fora de 1–120 s, potências invertidas, `id_produto` ≠ 3 dígitos, `ano` ≠ 2 dígitos
- `aprovados` é zerado apenas quando `numero_op` **muda**; reenvio com mesmo OP preserva progresso
- `proximo_sequencial` no mesmo OP usa `max(atual, payload)` — não regride acidentalmente
- Rejeitado durante `TESTING` ou `OTA_UPDATING`
- **ACK** em `status`: `{"tipo":"batch","evento":"configurado","numero_op":"...","estado":"BATCH_READY"}`
- Ao atingir `quantidade_total` aprovados, lote encerra automaticamente com `{"tipo":"batch","evento":"encerrado","motivo":"cota_atingida"}`

#### END_BATCH — Encerrar lote

```json
{ "cmd": "END_BATCH" }
```

Limpa NVS do lote e vai para `IDLE`. Rejeitado durante `TESTING`.

#### START_CALIBRATION — Modo calibração

```json
{ "cmd": "START_CALIBRATION" }
```

Mede 5 s, publica amostras em tempo real e média final em `calibracao`. Só aceito em `IDLE`. Usado pelo app na tela **Produtos** para autocalibrar SKUs.

#### OTA_UPDATE — Atualizar firmware

```json
{
  "cmd": "OTA_UPDATE",
  "url": "http://192.168.1.10:8080/sirene-validator.bin"
}
```

- URL deve começar com `http://` ou `https://`
- Rejeitado durante `TESTING`
- Relé desligado durante o download

### Mensagens publicadas pelo ESP32

#### Resultado de teste (`status`)

```json
{
  "tipo": "teste",
  "numero_op": "2026001",
  "id_produto": "123",
  "ano": "26",
  "veredito": "APROVADO",
  "potencia_media": 20.15,
  "sequencial": 1,
  "aprovados_no_lote": 1
}
```

#### Rejeição de comando (`status`)

```json
{
  "tipo": "rejeicao",
  "motivo": "set_batch_durante_teste"
}
```

Códigos de `motivo`:

| motivo | Causa |
|--------|-------|
| `json_invalido` | JSON malformado |
| `cmd_ausente` | Sem campo `cmd` |
| `cmd_desconhecido` | Comando não reconhecido |
| `payload_grande` | Payload ≥ 512 bytes |
| `set_batch_durante_teste` | SET_BATCH em TESTING |
| `set_batch_campos_invalidos` | Campos faltando |
| `end_batch_durante_teste` | END_BATCH em TESTING |
| `calibracao_estado_invalido` | Calibração fora de IDLE |
| `ota_estado_invalido` | OTA em TESTING |
| `ota_url_invalida` | URL vazia ou esquema inválido |
| `ota_falha_inicio` | Falha ao iniciar task OTA |
| `fila_cheia` | Fila interna de comandos MQTT cheia |
| `pzem_ocupado` | Calibração/teste já em andamento |
| `cmd_durante_teste` | Comando bloqueado durante TESTING |

#### Confirmação de lote (`status`) — v1.4+

```json
{
  "tipo": "batch",
  "evento": "configurado",
  "numero_op": "2026001",
  "estado": "BATCH_READY"
}
```

#### Heartbeat (`heartbeat`) — a cada 30 s

```json
{
  "uptime": 3600,
  "rssi": -62,
  "estado": "BATCH_READY",
  "fila": 0,
  "firmware_version": "1.4.0",
  "numero_op": "2026001",
  "proximo_sequencial": 3,
  "aprovados": 2
}
```

Sem lote ativo: `numero_op` vazio, `proximo_sequencial` e `aprovados` zerados.

Publicado **imediatamente** ao reconectar MQTT (além do intervalo de 30 s).

#### Presença (`presenca`)

- Conectado: `online` (retained)
- LWT (queda abrupta): `offline` (retained)

#### Calibração (`calibracao`)

Amostras durante o ciclo (a cada 500 ms após inrush):

```json
{
  "tipo": "calibracao_amostra",
  "potencia_w": 20.1,
  "elapsed_ms": 1500
}
```

Resultado final ao concluir os 5 s:

```json
{
  "tipo": "calibracao",
  "potencia_media": 20.42
}
```

O app Flutter usa as amostras para exibir leituras ao vivo e a média final para calcular `potencia_min`/`potencia_max` (tolerância padrão 10%).

#### Alerta hardware (`alerta`)

```json
{
  "tipo": "hardware",
  "falha": "pzem_uart"
}
```

#### Status OTA (`status`)

```json
{
  "tipo": "ota",
  "evento": "inicio",
  "detalhe": "http://192.168.1.10:8080/sirene-validator.bin"
}
```

Eventos: `inicio`, `sucesso`, `falha`.

---

## 9. Provisionamento Wi-Fi

### Primeira configuração

1. ESP32 sem credenciais NVS sobe o AP **`SireneValidator`** (aberto, sem senha)
2. IP do portal: **`http://192.168.4.1`**
3. Página lista redes do scan (com RSSI) + campo manual
4. Seção **Broker MQTT (opcional):** host e porta — se vazio, usa fallback de `board_config.h`
5. Ao salvar: firmware **valida conexão STA** (timeout 15 s) antes de gravar NVS
6. Senha incorreta → HTTP 400, credenciais **não** salvas
7. Sucesso → reinicia conectado à rede de fábrica

### Credenciais persistidas

| NVS namespace | Chave | Conteúdo |
|---------------|-------|----------|
| `wifi_cfg` | `ssid` | Nome da rede |
| `wifi_cfg` | `pass` | Senha Wi-Fi |
| `mqtt_cfg` | `host` | Host do broker MQTT (opcional) |
| `mqtt_cfg` | `port` | Porta do broker MQTT (padrão 1883) |

### Reprovisionar

- Apagar NVS: `idf.py erase-flash` (apaga tudo) ou ferramenta NVS
- Ou: falha de conexão STA no boot → volta automaticamente ao portal
- Para **alterar broker MQTT** sem reflash: acesse o portal novamente e informe novo host/porta

### No app Flutter (Windows)

1. FAB Wi-Fi na tela Dispositivos
2. Conectar PC à rede `SireneValidator`
3. Abrir portal no navegador (`http://192.168.4.1`) ou usar botão integrado

---

## 10. Persistência offline

### Lote ativo (NVS — namespace `batch`)

Sobrevive a reboot e queda de energia:

- `numero_op`, `id_produto`, `ano`
- `tempo_teste`, `potencia_min`, `potencia_max`
- `quantidade_total`, `proximo_sequencial`, `aprovados`

### Fila de mensagens (SPIFFS — partição `storage`)

- Máximo **64** mensagens JSON
- FIFO: descarta a mais antiga quando cheia
- Sincroniza para MQTT ao reconectar (publica em `status`)
- Sync imediato ao reconectar + polling a cada 5 s

---

## 11. OTA (atualização remota)

### Pré-requisitos

- Partições `ota_0` + `ota_1` + `otadata` (layout em `partitions.csv`)
- Primeira gravação com layout OTA: **obrigatoriamente por cabo USB**
- Servidor HTTP(S) servindo o `.bin` na mesma rede

### Servir binário (exemplo)

```bash
cd /tmp/sv_build  # ou diretório do build
python3 -m http.server 8080
# URL: http://<IP_DO_PC>:8080/sirene-validator.bin
```

### Disparar via MQTT

```json
{
  "cmd": "OTA_UPDATE",
  "url": "http://192.168.1.10:8080/sirene-validator.bin"
}
```

### Fluxo

1. Valida URL (`http://` ou `https://`)
2. Estado → `OTA_UPDATING`, relé desligado
3. Download via `esp_https_ota` para partição inativa
4. Sucesso → reinicia com nova imagem
5. Boot saudável → `esp_ota_mark_app_valid_cancel_rollback()`
6. Boot com falha → **rollback automático** para imagem anterior

### Script de bancada

```bash
BROKER=192.168.1.100 DEVICE_ID=aabbccddeeff \
  OTA_URL=http://192.168.1.10:8080/sirene-validator.bin \
  ./scripts/bench_ota.sh
```

---

## 12. Telemetria e robustez

| Recurso | Implementação |
|---------|---------------|
| LWT presença | `offline` retained em queda abrupta |
| Heartbeat | 30 s + imediato ao reconectar |
| TWDT | Worker task e telemetry alimentam watchdog (timeout 30 s) |
| Reconexão Wi-Fi | Backoff exponencial 1 s → 30 s + jitter |
| Reconexão MQTT | Backoff exponencial 1 s → 30 s + jitter |
| Worker task | Comandos MQTT e botão processados fora do callback MQTT |
| Relé seguro | GPIO desligado antes de qualquer lógica no boot |

---

## 13. Particionamento de flash

Arquivo: `partitions.csv` (flash 4 MB)

| Partição | Tipo | Tamanho | Uso |
|----------|------|---------|-----|
| `nvs` | data/nvs | 24 KB | Wi-Fi, lote, metadados fila |
| `otadata` | data/ota | 8 KB | Seletor de slot OTA |
| `phy_init` | data/phy | 4 KB | Calibração RF |
| `ota_0` | app/ota_0 | 1,5 MB | Firmware slot A |
| `ota_1` | app/ota_1 | 1,5 MB | Firmware slot B |
| `storage` | data/spiffs | 384 KB | Fila offline JSON |

---

## 14. Compilação e gravação

### Requisitos

- ESP-IDF v5.3+ (testado com v6.1)
- ESP32 com 4 MB flash

### Build

```bash
cd sirene-validator
idf.py set-target esp32
idf.py build
```

> **Caminho com acentos:** use build dir ASCII:
> `idf.py -B /tmp/sv_build build`

### Flash

```bash
idf.py -p /dev/ttyUSB0 flash monitor
# ou com build dir alternativo:
idf.py -B /tmp/sv_build -p /dev/ttyUSB0 flash monitor
```

### Testes de host (sem hardware)

```bash
./scripts/run_host_tests.sh
```

Cobre: veredito, FIFO, FSM, serial, validação URL OTA.

---

## 15. App Flutter companion

Local: `sirene_app/` (Windows desktop em produção)

### Configuração no posto

| Parâmetro | Padrão | Onde configurar |
|-----------|--------|-----------------|
| Broker MQTT host | `192.168.1.100` | App → Configurações |
| Broker MQTT porta | `1883` | App → Configurações |
| Impressora Zebra IP | `192.168.1.50` | App → Configurações |
| Impressora porta | `9100` | App → Configurações |

### Fluxo do operador (tela inicial: Lote)

1. **Selecionar operador** — obrigatório no início do turno (chip no cabeçalho; persistido na sessão).
2. **Configurar lote** — na tela **Lote** (hub principal): OP, produto, limites, `SET_BATCH`.
3. **Acompanhar testes** — dashboard ao vivo na mesma tela (estado FSM, aprovados/reprovados).
4. **Imprimir etiquetas** — buffer ZPL a partir dos aprovados.
5. **Cadastros** (admin) — produtos e operadores na mesma tela, abas **Produtos** / **Operadores**.
6. **Dispositivo** — em **Configurações → Dispositivo** (não é mais a tela inicial); descoberta MQTT em background.

> A tela **Dispositivos** deixou de ser a rota inicial. O operador de bancada começa pelo lote, não pela infraestrutura MQTT.

### Funcionalidades

- Seleção e cadastro de **operadores** (SQLite local; sync opcional Firestore `operators`)
- Tela **Lote** como hub operacional (configuração + dashboard ao vivo)
- Descoberta automática de dispositivos (`sirene/+/heartbeat`) em Configurações
- Configuração de lote (`SET_BATCH` / `END_BATCH`) com vínculo `operador_id` / `operador_nome`
- Monitoramento em tempo real (estado FSM, resultados)
- Geração de serial ITF 2 de 5 em aprovações
- Buffer de etiquetas ZPL (múltiplos de 3)
- Calibração e OTA (seção Admin)
- Provisionamento Wi-Fi guiado
- Indicadores de status MQTT/dispositivo no cabeçalho global

### Build Windows

```bash
cd sirene_app
flutter pub get
dart run build_runner build
flutter build windows --release
```

Saída: `build/windows/x64/runner/Release/`

---

## 16. Firebase / Firestore (implementado no app)

> **Importante:** o firmware ESP32 **não se conecta ao Firebase**. A sincronização é feita pelo **app Flutter** de forma assíncrona e offline-first.

### Por que não está no firmware?

- ESP32 opera offline na linha — Firebase exigiria internet estável
- MQTT já cobre comunicação em tempo real na LAN
- Serial, etiquetas e histórico são responsabilidade do app

### Arquitetura recomendada (fase 2)

```
ESP32 ──MQTT──► Mosquitto ──► App Flutter ──► Firestore
                                    │
                                    └──► Cloud Functions (opcional)
```

### Esquema Firestore sugerido

#### Coleção `devices`

```json
{
  "device_id": "aabbccddeeff",
  "firmware_version": "1.2.0",
  "last_seen": "2026-06-10T14:30:00Z",
  "estado": "BATCH_READY",
  "online": true
}
```

#### Coleção `operators`

```json
{
  "nome": "Maria Silva",
  "matricula": "OP-042",
  "ativo": true,
  "station_id": "posto-01",
  "updated_at": "2026-06-10T08:00:00Z"
}
```

#### Coleção `test_results`

```json
{
  "device_id": "aabbccddeeff",
  "numero_op": "2026001",
  "operador_id": 42,
  "operador_nome": "Maria Silva",
  "veredito": "APROVADO",
  "potencia_media": 20.15,
  "sequencial": 1,
  "serial": "1232600018",
  "timestamp": "2026-06-10T14:31:00Z"
}
```

Chave de idempotência: `numero_op` + `sequencial` (evita duplicatas após reconexão).

#### Coleção `batches`

```json
{
  "numero_op": "2026001",
  "id_produto": "123",
  "ano": "26",
  "quantidade_total": 10,
  "aprovados": 3,
  "device_id": "aabbccddeeff",
  "operador_id": 42,
  "operador_nome": "Maria Silva",
  "started_at": "2026-06-10T14:00:00Z",
  "status": "active"
}
```

### Comportamento no app (offline-first)

1. **SQLite permanece primário** — MQTT, lotes, etiquetas e catálogo funcionam sem internet.
2. Com sync habilitado em **Configurações → Nuvem**, o app enfileira gravações em `SyncQueue` (Drift) e envia ao Firestore quando online.
3. Login Firebase (e-mail/senha) é obrigatório para habilitar sync.
4. Eventos sincronizados automaticamente:
   - `tipo: "teste"` → `test_results/{numero_op}_{sequencial}` (inclui `operador_id`, `operador_nome`)
   - heartbeat / presença → `devices/{device_id}` (debounce 60 s; offline imediato)
   - `SET_BATCH` / `END_BATCH` → `batches/{numero_op}` (inclui `operador_id`, `operador_nome`)
   - cadastro/recalibração de produto → `products/{id_produto}`
   - cadastro/edição de operador → `operators/{id}`

### Como configurar Firebase (primeira vez)

1. Criar projeto em [Firebase Console](https://console.firebase.google.com) (sugestão: região `southamerica-east1`, Firestore Standard).
2. Ativar **Authentication** → provedor E-mail/senha; criar contas de operador.
3. Ativar **Cloud Firestore**.
4. Na raiz do repositório, vincular projeto e publicar regras:
   ```bash
   firebase login
   firebase use <project-id>
   firebase deploy --only firestore
   ```
   Arquivos versionados: `firebase.json`, `firebase/firestore.rules`, `firebase/firestore.indexes.json`.
5. No app:
   ```bash
   cd sirene_app
   dart pub global activate flutterfire_cli
   flutterfire configure
   flutter pub get
   dart run build_runner build
   ```
   O `lib/firebase_options.dart` gerado substitui o stub (`isConfigured = true`).
6. No posto: **Configurações → Nuvem** → definir `station_id` → login → habilitar sincronização.

### Operação sem nuvem

O sync inicia **desabilitado**. Para produção apenas com SQLite local, não habilite o toggle — nenhuma alteração no fluxo MQTT/etiquetas.

---

## 17. Rastreabilidade e etiquetas

Responsabilidade do **app Flutter**, não do firmware.

### Número de série (10 dígitos)

```
[ID produto: 3] [Ano: 2] [Sequencial: 4] [Verificador ITF: 1]
     123           26         0001              8
     └────────────────── 1232600018 ──────────────────┘
```

- Sequencial vem do ESP32 (só incrementa em APROVADO)
- Dígito verificador: módulo 10, pesos 3,1,3,1... da direita (GS1)

### Impressão Zebra ZT230

- Etiquetas 10×30 mm, 3 colunas por linha
- Impressão em múltiplos de 3 (ZPL via TCP porta 9100)
- Botão "Imprimir pendentes" para órfãs (1–2 seriais)

---

## 18. Segurança e limitações

| Item | Status | Risco |
|------|--------|-------|
| MQTT TLS | Não implementado | Qualquer cliente na LAN pode comandar |
| MQTT auth | Não implementado | Sem usuário/senha |
| Portal Wi-Fi | HTTP plano, AP aberto | Credenciais visíveis no AP |
| OTA signing | Sem Secure Boot | Imagem não assinada criptograficamente |
| NVS encryption | Não habilitado | Senha Wi-Fi em texto no flash |

Aceito para **rede industrial isolada** de chão de fábrica. Para ambientes expostos, considerar: TLS MQTT, senha no AP, HTTPS no portal.

### Limitações funcionais

- Broker MQTT só muda recompilando firmware
- Sem comando remoto de teste (botão obrigatório)
- Sem ACK de `SET_BATCH` (usar heartbeat)
- `quantidade_total` não encerra lote automaticamente
- Fila offline republica tudo em `status` (perde tópico original)

---

## 19. Testes e validação

### Testes automatizados (host)

```bash
cd sirene-validator && ./scripts/run_host_tests.sh
```

### Scripts de bancada MQTT

```bash
# Telemetria
BROKER=192.168.1.100 DEVICE_ID=<id> ./scripts/bench_mqtt_telemetry.sh

# OTA
OTA_URL=http://192.168.1.10:8080/sirene-validator.bin \
  DEVICE_ID=<id> ./scripts/bench_ota.sh

# Reconexão (cortar Wi-Fi/broker manualmente)
DEVICE_ID=<id> ./scripts/bench_reconnect.sh
```

### Plano completo

Ver [TESTING.md](TESTING.md) para checklist detalhado de bancada.

---

## 20. Referência rápida

### Constantes principais (`board_config.h`)

| Constante | Valor | Descrição |
|-----------|-------|-----------|
| `GPIO_RELAY` | 26 | Relé |
| `GPIO_BUTTON` | 27 | Botão |
| `GPIO_LED_STATUS` | 25 | LED |
| `GPIO_BUZZER` | 33 | Buzzer |
| `PZEM_TX_PIN` | 17 | UART TX |
| `PZEM_RX_PIN` | 16 | UART RX |
| `MQTT_BROKER_URI` | mqtt://192.168.1.100:1883 | Broker |
| `WIFI_AP_SSID` | SireneValidator | AP provisionamento |
| `WIFI_AP_IP` | 192.168.4.1 | Portal |
| `HEARTBEAT_INTERVAL_SEC` | 30 | Intervalo heartbeat |
| `INRUSH_DISCARD_MS` | 500 | Descarte inrush |
| `OFFLINE_QUEUE_MAX` | 64 | Máx. fila offline |
| `CALIBRATION_SAMPLE_MS` | 500 | Intervalo amostras calibração |
| `FIRMWARE_VERSION` | 1.2.0 | Versão |

### Comandos úteis

```bash
# Build firmware
idf.py -B /tmp/sv_build build

# Flash
idf.py -B /tmp/sv_build -p /dev/ttyUSB0 flash monitor

# Testes host
./scripts/run_host_tests.sh

# Monitorar MQTT
mosquitto_sub -h 192.168.1.100 -v -t 'sirene/+/heartbeat' -t 'sirene/+/status'

# Build app Windows
cd ../sirene_app && flutter build windows --release
```

---

*Documento gerado para o projeto Diponto Sirene Validator. Para dúvidas sobre specs formais, consulte `openspec/specs/` no repositório.*
