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

## Bancada sem PZEM (mock de desenvolvimento)

Para exercitar o ciclo completo botão → relé → veredito → MQTT **sem** o sensor PZEM-004T:

```bash
cd sirene-validator
idf.py menuconfig
# Component config → PZEM → Enable "Use mock PZEM readings (development only)"
idf.py build flash monitor
```

O firmware gera amostras de potência sintéticas (~70% dentro de 18–22 W). **Não habilite em produção.**

No app Flutter (modo debug), use **Lote → dashboard ao vivo → Simular teste (dev)** para injetar resultados fictícios sem hardware.

## App Flutter — operador e fluxo lote-primeiro

### 15.1 Seleção de operador

1. Abra o app — a primeira tela deve ser **Lote** (não Dispositivos).
2. Sem operador selecionado, tente configurar lote — o app deve bloquear e exibir seletor de operador.
3. Selecione um operador ativo — o nome deve aparecer no cabeçalho (chip "Operador: …").
4. Feche e reabra o app — o operador deve permanecer selecionado na sessão.
5. Troque de operador pelo chip no cabeçalho (sem teste em andamento) — lotes e testes subsequentes devem usar o novo operador.

### 15.2 Cadastro de operadores

1. Acesse **Cadastros → aba Operadores** (admin).
2. Cadastre operador com nome obrigatório e matrícula opcional.
3. Tente matrícula duplicada — deve exibir erro de validação.
4. Desative um operador — não deve aparecer na seleção do posto, mas permanece em histórico.

### 15.3 Dispositivo em Configurações

1. Com `device_id` não configurado, a tela **Lote** deve exibir banner com link para **Configurações → Dispositivo**.
2. Em Configurações, confirme descoberta via heartbeat e seleção do ESP32 alvo.
3. O cabeçalho global deve indicar status MQTT e dispositivo (online/offline).

### 15.4 Rastreabilidade operador → lote → teste

1. Selecione operador, configure lote e aprove uma peça (hardware ou simulação debug).
2. Verifique no SQLite local (ou sync Firestore, se habilitado) que `batches` e `test_results` contêm `operador_id` e `operador_nome`.
3. Com sync habilitado, confirme documentos em `operators`, `batches` e `test_results` no Firestore.

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

## 10.8 Robustez de fila, comandos e cota (firmware 1.4+)

1. **Fila offline com tópico:** desligue o broker, force falha PZEM (alerta) ou conclua calibração offline; reconecte e confirme que alertas vão para `sirene/<device_id>/alerta` e calibração (incluindo `calibracao_amostra`) para `calibracao`, não para `status`.
2. **Comando obsoleto:** com teste em andamento (`TESTING`), publique `END_BATCH` ou `SET_BATCH` — deve haver rejeição imediata em `status` com motivo `cmd_durante_teste`, sem encerrar o lote após o teste.
3. **Cota de lote:** configure `SET_BATCH` com `quantidade_total: 2`, aprove duas peças; o firmware deve publicar `{"tipo":"batch","evento":"encerrado","motivo":"cota_atingida"}` e ir para `IDLE` automaticamente.
4. **ACK de SET_BATCH:** após `SET_BATCH` válido, confirme `{"tipo":"batch","evento":"configurado",...}` em `status`.
5. **SET_BATCH mesmo OP:** com 2 aprovados, reenvie `SET_BATCH` com mesmo `numero_op` e novos limites — `aprovados` deve permanecer 2.
6. **Validação:** envie `potencia_min` > `potencia_max` — rejeição `set_batch_campos_invalidos`.
7. **Heartbeat:** com lote ativo, confirme campos `numero_op`, `proximo_sequencial`, `aprovados` no heartbeat.

## 10.5 Falha UART PZEM

1. Desconecte TX/RX do PZEM.
2. Reinicie o ESP32 — autoteste no boot deve publicar alerta `pzem_uart_boot` em `alerta`.
3. Envie `{ "cmd": "PZEM_PROBE" }` — resposta deve ter `"uart_ok": false`.
4. Reconecte PZEM (TX cruzado: ESP GPIO 27 → RX PZEM, ESP GPIO 26 ← TX PZEM, GND comum).
5. Envie `PZEM_PROBE` novamente — `"uart_ok": true`.
6. Testes manuais devem voltar após recuperação automática (`hw_mon`).

## 10.5b PZEM_PROBE remoto

1. Com PZEM conectado e sem teste em andamento, publique em `sirene/<device_id>/comando`:
   ```json
   { "cmd": "PZEM_PROBE" }
   ```
2. Confirme em `status`: `{"tipo":"pzem","evento":"probe","potencia_w":...,"uart_ok":true}`.
3. Durante `TESTING`, o comando deve ser rejeitado com `cmd_durante_teste`.

## 10.6 Rejeição por conflito de estado

| Comando | Estado | Resultado esperado |
|---------|--------|-------------------|
| `SET_BATCH` | `TESTING` | Rejeição imediata (`cmd_durante_teste`), sem enfileiramento |
| `END_BATCH` | `TESTING` | Rejeição imediata (`cmd_durante_teste`), sem enfileiramento |
| `OTA_UPDATE` | `TESTING` | Rejeição imediata (`cmd_durante_teste`) |
| `PZEM_PROBE` | `TESTING` | Rejeição imediata (`cmd_durante_teste`) |
| `START_CALIBRATION` | `BATCH_READY` | Rejeição |
| `START_CALIBRATION` | `IDLE` | Aceito |

## 10.7 Contratos MQTT ponta a ponta

Validar com App Web os tópicos:

- `sirene/<device_id>/comando` — `SET_BATCH`, `END_BATCH`, `START_CALIBRATION`, `PZEM_PROBE`, `OTA_UPDATE`
- `sirene/<device_id>/status` — resultados e rejeições
- `sirene/<device_id>/calibracao` — amostras `calibracao_amostra` + média `calibracao`
- `sirene/<device_id>/alerta` — falhas de hardware

## 11. OTA remoto (`OTA_UPDATE`)

### Checklist rápido

1. `idf.py build` → `build/sirene-validator.bin`
2. Sirva o binário na LAN: `cd build && python3 -m http.server 8080`
3. Descubra `device_id` via `mosquitto_sub -t 'sirene/+/heartbeat'`
4. Publique em `sirene/<device_id>/comando`:

```json
{ "cmd": "OTA_UPDATE", "url": "http://192.168.1.10:8080/sirene-validator.bin" }
```

5. Confirme progresso/falha em `sirene/<device_id>/status` (JSON com `tipo: "ota"`)
6. Após reboot, verifique `firmware_version` no heartbeat (ex.: `"1.4.1"`)

Ou use o script:

```bash
DEVICE_ID=<id> ./scripts/serve_firmware_and_ota.sh
```

### Cenários adicionais

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
