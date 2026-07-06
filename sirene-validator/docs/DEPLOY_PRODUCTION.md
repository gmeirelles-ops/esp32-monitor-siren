# Deploy em produção industrial — sirene-validator

Checklist para colocar bancadas em linha de produção com firmware **≥ 1.7.0**.

## Perfis de build

| Perfil | Arquivo | OTA apaga NVS? | Uso |
|--------|---------|----------------|-----|
| **Produção** | `sdkconfig.defaults` + `sdkconfig.defaults.production` | Não | Bancadas em campo |
| **Fábrica/reprovisionamento** | `sdkconfig.defaults.provisioning` | Sim | Linha de montagem inicial |

```bash
idf.py build
```

## Infraestrutura MQTT

1. Broker cloud **mqtt.diponto.com** (ESP: `mqtts://` porta **443**; app: **WSS** `/ws` na 443).
2. Hierarquia de tópicos: `producao/bancada-{NN}/{suffix}` — **sem MAC no path** (`device_id` permanece no JSON do heartbeat).
3. Portal `http://192.168.4.1`: Wi-Fi, **número da bancada (1–99)**, broker, usuário, senha, **TLS**.
4. Validar heartbeat (campos `device_id`, `bancada`, `site`, `fila_drops`, `pzem_faults`, `reset_reason`, `time_synced`):

```bash
mosquitto_sub -h mqtt.diponto.com -p 443 -u <user> -P <pass> -t 'producao/+/heartbeat' -v
```

### Exemplo ACL Mosquitto (por bancada)

```
user devices-bancada-01
topic readwrite producao/bancada-01/#
```

App administrativo pode usar usuário `devices` com ACL `producao/#` readwrite.

## Primeira gravação por bancada

1. Flash USB: `idf.py -p /dev/ttyUSB0 flash`
2. Conectar ao AP `SireneValidator` — senha **derivada do MAC** (`svXXXXXX`, exibida no portal)
3. Provisionar Wi-Fi + broker no portal
4. Calibrar produto e teste de fumaça (1 OK + 1 NOK) no app Flutter

## Segurança e robustez (v1.7.0)

| Recurso | Comportamento |
|---------|----------------|
| OTA whitelist | Só URLs em LAN privada / `*.local` |
| OTA smoke test | PZEM probe antes de confirmar imagem; rollback se falhar |
| Fila offline | **Não descarta** mensagens — alerta LED + `fila_drops` no heartbeat |
| Mutex lote | Acesso thread-safe ao contexto de lote |
| PZEM | Auto-detecta endereço Modbus `0x01` ou `0xF8` |
| Timestamps | `ts_ms` e `ts_unix` (SNTP) nos resultados de teste |
| CI | GitHub Actions executa `run_host_tests.sh` em cada push |

## OTA

```json
{ "cmd": "OTA_UPDATE", "url": "http://192.168.51.10/firmware/sirene-validator.bin" }
```

Manter binário **N-1** no servidor interno para rollback manual.

## Monitoramento

| Sinal | Tópico / campo | Ação |
|-------|----------------|------|
| Offline | `presenca` LWT | Alerta > 2 min |
| Fila cheia | `heartbeat.fila_drops` > 0 | Verificar MQTT / broker |
| Falha NVS | `alerta` `batch_nvs_fault` | Parar linha |
| Falha PZEM | `alerta` + `pzem_faults` | Manutenção |

## Integração app

Copiar `dist/sirene_app/lib/*` para o `sirene_app` — ver `dist/INTEGRATION.md`.
