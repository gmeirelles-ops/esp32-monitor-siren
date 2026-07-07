# sirene-validator

Firmware ESP32 para validação de potência e rastreabilidade de sirenes em linha de produção.

## Requisitos

- ESP-IDF v5.3+ (testado com v6.1)
- ESP32 com flash de 4 MB
- PZEM-004T (UART), relé, botão e LED/buzzer

## Build

```bash
cd sirene-validator
idf.py set-target esp32
idf.py build
idf.py -p /dev/ttyUSB0 flash monitor
```

> **Caminho com acentos/espaços (ex.: `Área de trabalho`):** o ESP-IDF 6.1 corrompe a flag `-specs` (picolibc) quando o caminho do projeto contém caracteres não-ASCII, quebrando o build. Sem mover o projeto, direcione o diretório de build para um caminho ASCII:
>
> ```bash
> idf.py -B /tmp/sv_build build
> idf.py -B /tmp/sv_build -p /dev/ttyUSB0 flash monitor
> ```

### Migração para particionamento OTA

A versão com hardening de produção usa partições `ota_0`/`ota_1` em vez de `factory`. A **primeira gravação** após essa mudança deve ser feita **por cabo** (`idf.py flash`), pois o layout de flash mudou. Dispositivos já em campo perdem NVS se a partição `nvs` mudar de offset — reprovisione Wi-Fi e reconfigure o lote após a migração.

## Configuração

Edite `components/board_config/include/board_config.h`:

- `MQTT_BROKER_URI` — endereço do broker MQTT
- `FIRMWARE_VERSION` — versão reportada no heartbeat
- GPIOs do relé, botão, LED, buzzer e UART do PZEM

## Novidades (hardening produção v1.7.0)

| Recurso | Descrição |
|---------|-----------|
| OTA | Comando MQTT `OTA_UPDATE` — URLs só em LAN privada / `*.local` |
| MQTT auth | Usuário/senha via portal Wi-Fi e NVS |
| Lote NVS | Validação no boot; alerta `batch_nvs_fault` se persistência falhar |
| PZEM | Auto-detect `0x01` / `0xF8`; smoke test pós-OTA |
| Fila offline | Sem descarte silencioso; `fila_drops` no heartbeat |
| Timestamps | `ts_ms` + `ts_unix` (SNTP) nos testes |
| TLS MQTT | Opcional via portal (`mqtts://`) |
| AP Wi-Fi | Senha derivada do MAC por dispositivo |
| CI | GitHub Actions com testes host |
| Telemetria | LWT `presenca` (online/offline) + heartbeat periódico |
| Robustez | TWDT, reconexão Wi-Fi/MQTT com backoff exponencial + jitter |
| Portal | Scan com RSSI, broker MQTT + auth, validação STA antes de salvar |
| Worker task | Operações longas fora do callback MQTT |

Deploy industrial: [docs/DEPLOY_PRODUCTION.md](docs/DEPLOY_PRODUCTION.md).

## Testes de host (CI)

```bash
./scripts/run_host_tests.sh
```

Testa lógica pura (`pure_logic`): veredito, FIFO, FSM, serial, URL OTA, batch, reteste, ensaio, site e hosts LAN.

## Testes em bancada

Ver [docs/TESTING.md](docs/TESTING.md).
