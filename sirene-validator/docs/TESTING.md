# Plano de Testes — Validador de Sirenes

Testes manuais em bancada com ESP32, PZEM-004T, relé, botão e LED/buzzer.

## Pré-requisitos

- Firmware compilado (ver nota de caminho abaixo)
- Broker MQTT acessível (ajustar `MQTT_BROKER_URI` em `components/board_config/include/board_config.h`)
- Cliente MQTT para publicar comandos (mosquitto_pub, App Web)
- Para OTA: servidor HTTP(S) servindo o binário `sirene-validator.bin`

> **Nota:** Se o caminho do projeto contiver acentos (ex.: `Área de trabalho`), compile a partir de um diretório sem caracteres especiais:
> `rsync -a sirene-validator/ /tmp/sirene-validator/ && cd /tmp/sirene-validator && idf.py fullclean && idf.py build`

> **Primeira gravação com layout OTA:** após migrar para partições `ota_0`/`ota_1`, grave por cabo (`idf.py flash`). Pode apagar NVS — reprovisione Wi-Fi e lote.

## Testes de host (CI)

Executar lógica pura sem hardware:

```bash
cd sirene-validator && ./scripts/run_host_tests.sh
```

Cobre: veredito de potência, anel FIFO, transições da FSM, composição do serial de 10 dígitos, validação de URL OTA e cota de lote (`quantidade_total`).

## Scripts de bancada (MQTT)

Com `mosquitto-clients` instalado e `DEVICE_ID` do ESP32:

```bash
# Telemetria (seções 12)
BROKER=192.168.1.100 DEVICE_ID=aabbccddeeff ./scripts/bench_mqtt_telemetry.sh

# OTA (seção 11)
BROKER=192.168.1.100 DEVICE_ID=aabbccddeeff \
  OTA_URL=http://192.168.1.10:8080/sirene-validator.bin \
  ./scripts/bench_ota.sh

# Reconexão (seção 13) — corte Wi-Fi/broker manualmente durante execução
BROKER=192.168.1.100 DEVICE_ID=aabbccddeeff ./scripts/bench_reconnect.sh
```

## 10.1 Provisionamento (SoftAP → STA)

1. Apague credenciais NVS ou use chip virgem.
2. Reinicie o ESP32 — deve subir AP `SireneValidator`.
3. Conecte ao AP e acesse `http://192.168.4.1`.
4. Informe SSID/senha da rede e salve.
5. Após reboot, confirme conexão STA nos logs (`device_id=...`, `sistema pronto`).

## 10.2 Ciclo aprovado/reprovado e sequencial

1. Publique `SET_BATCH` em `sirene/<device_id>/comando`:

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

2. Pressione o botão com sirene dentro dos limites → veredito `APROVADO`, sequencial incrementa.
3. Pressione com sirene fora dos limites → `REPROVADO`, sequencial permanece igual.
4. Confirme feedback local (LED/buzzer) em ambos os casos.

## 10.3 Retomada de lote após reboot

1. Configure lote e aprove pelo menos uma peça.
2. Reinicie o ESP32 (ou corte energia).
3. Verifique nos logs que o lote foi restaurado (`lote restaurado OP=...`).
4. Próximo teste deve usar o sequencial correto.

## 10.4 Resiliência offline e fila FIFO

1. Desligue broker MQTT ou Wi-Fi.
2. Execute testes — dispositivo deve continuar operando.
3. Verifique fila local (logs / SPIFFS).
4. Restaure rede — mensagens devem sincronizar em ordem FIFO, **cada uma no tópico original** (`status`, `alerta` ou `calibracao`).

## 10.8 Robustez de fila, comandos e cota (firmware 1.3+)

1. **Fila offline com tópico:** desligue o broker, force falha PZEM (alerta) ou conclua calibração offline; reconecte e confirme que alertas vão para `sirene/<device_id>/alerta` e calibração para `calibracao`, não para `status`.
2. **Comando obsoleto:** com teste em andamento (`TESTING`), publique `END_BATCH` ou `SET_BATCH` — deve haver rejeição imediata em `status` com motivo `cmd_durante_teste`, sem encerrar o lote após o teste.
3. **Cota de lote:** configure `SET_BATCH` com `quantidade_total: 2`, aprove duas peças; ao pressionar o botão novamente, o relé não deve acionar e deve haver rejeição `lote_cheio` (se MQTT conectado) e feedback local de reprovação.

## 10.5 Falha UART PZEM

1. Desconecte TX/RX do PZEM.
2. Tente iniciar teste — deve bloquear e publicar alerta em `sirene/<device_id>/alerta`.
3. Reconecte PZEM — após recuperação, testes devem voltar.

## 10.6 Rejeição por conflito de estado

| Comando | Estado | Resultado esperado |
|---------|--------|-------------------|
| `SET_BATCH` | `TESTING` | Rejeição imediata (`cmd_durante_teste`), sem enfileiramento |
| `END_BATCH` | `TESTING` | Rejeição imediata (`cmd_durante_teste`), sem enfileiramento |
| `OTA_UPDATE` | `TESTING` | Rejeição imediata (`cmd_durante_teste`) |
| `START_CALIBRATION` | `BATCH_READY` | Rejeição |
| `START_CALIBRATION` | `IDLE` | Aceito |

## 10.7 Contratos MQTT ponta a ponta

Validar com App Web os tópicos:

- `sirene/<device_id>/comando` — `SET_BATCH`, `END_BATCH`, `START_CALIBRATION`
- `sirene/<device_id>/status` — resultados e rejeições
- `sirene/<device_id>/calibracao` — amostras `calibracao_amostra` + média `calibracao`
- `sirene/<device_id>/alerta` — falhas de hardware

## 11. OTA remoto (`OTA_UPDATE`)

1. Sirva o binário em URL HTTP acessível pelo ESP32 (ex.: `http://192.168.1.10:8080/sirene-validator.bin`).
2. Publique em `sirene/<device_id>/comando`:

```json
{ "cmd": "OTA_UPDATE", "url": "http://192.168.1.10:8080/sirene-validator.bin" }
```

3. Confirme progresso/falha em `sirene/<device_id>/status` (JSON com `tipo: "ota"`).
4. Após reboot, verifique `firmware_version` no heartbeat.
5. **Rejeição durante teste:** inicie um teste e envie `OTA_UPDATE` — deve ser rejeitado sem desligar o relé no meio do ciclo.
6. **Rollback (opcional):** grave uma imagem inválida ou force falha antes da marca de validação; no próximo boot o firmware anterior deve voltar.

## 12. Telemetria (presença + heartbeat)

1. Conecte o dispositivo ao broker e assine `sirene/<device_id>/presenca` (retained).
2. Após conexão MQTT, confirme payload `online` retido.
3. Desligue o ESP32 abruptamente (sem `disconnect`) — o broker deve publicar LWT `offline` retido.
4. Assine `sirene/<device_id>/heartbeat` e confirme publicação periódica com `uptime`, `rssi`, `estado`, `fila`, `firmware_version`.

## 13. Reconexão Wi-Fi/MQTT e watchdog

1. Com lote ativo, desligue o roteador por ~30 s e religue.
2. O dispositivo deve reconectar (backoff nos logs) sem energizar o relé sozinho.
3. Durante um teste em andamento, corte Wi-Fi brevemente — o ciclo local deve completar; mensagens enfileiram e sincronizam após reconexão.
4. Verifique nos logs que tarefas críticas alimentam o TWDT durante medição prolongada.

## 14. Provisionamento com scan e validação

1. Apague credenciais NVS ou use chip virgem; reinicie em modo AP.
2. Acesse `http://192.168.4.1` — a página deve listar redes encontradas no scan.
3. Selecione um SSID da lista ou digite manualmente; use senha **correta** — após submit, o portal deve validar STA e reiniciar conectado.
4. Repita com senha **incorreta** — o portal deve permanecer aberto com indicação de falha, sem gravar credenciais na NVS.
