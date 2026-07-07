# MQTT Status Contract — Firmware → App

**Topic**: `{site}/bancada-{NN}/status`  
**QoS**: 1

## Test result (CRÍTICO para aprovação)

```json
{
  "tipo": "teste",
  "ts_ms": 6647451,
  "ts_unix": 1783453590,
  "numero_op": "1320",
  "id_produto": "072",
  "ano": "26",
  "veredito": "APROVADO",
  "potencia_media": 39.63,
  "sequencial": 502,
  "aprovados_no_lote": 3
}
```

**App parser**: `parseMqttStatusPayload` → `processTestResult`  
**Campos obrigatórios para parse**: `tipo`, `numero_op`, `id_produto`, `ano`, `veredito`, `potencia_media`, `sequencial`, `aprovados_no_lote`

## Rejection

```json
{"tipo": "rejeicao", "motivo": "lote_cheio"}
```

## Batch lifecycle (NÃO parseado pelo app — gap)

```json
{"tipo": "batch", "evento": "configurado", "ts_ms": 0, "numero_op": "...", "estado": "BATCH_READY"}
{"tipo": "batch", "evento": "encerrado", "motivo": "cota_atingida"}
```

## OTA (parseado globalmente em mqtt_service)

```json
{"tipo": "ota", "evento": "inicio|sucesso|falha", "detalhe": "..."}
```

## Compatibility matrix

| tipo | App parse | Ação se ausente |
|------|-----------|-----------------|
| `teste` | ✅ | Perda de aprovação/serial |
| `rejeicao` | ✅ | Operador sem feedback |
| `batch` | ❌ | Depende de heartbeat |
| `ota` | ✅ | OTA screen |
| `pzem` | ❌ | — |
| `wifi` | ❌ | — |
| `station` | ❌ | — |

## Payload corruption recovery

App MUST aceitar payloads colados via `MqttParser.tryParseJsonObjects` + `sanitizeCorruptedJson`.

Exemplo de payload problemático observado em produção:
```
{"tipo":"teste",...,"ano":"26{"tipo":"teste",...,"","","veredito":"APROVADO",...}
```
