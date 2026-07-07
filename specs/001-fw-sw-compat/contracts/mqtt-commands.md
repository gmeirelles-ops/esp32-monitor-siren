# MQTT Command Contract — App → Firmware

**Topic**: `{site}/bancada-{NN}/comando`  
**QoS**: 1  
**Encoding**: UTF-8 JSON

## SET_BATCH

```json
{
  "cmd": "SET_BATCH",
  "numero_op": "12345",
  "id_produto": "071",
  "ano": "26",
  "tempo_teste": 5,
  "potencia_min": 18.0,
  "potencia_max": 22.0,
  "quantidade_total": 100,
  "proximo_sequencial": 501,
  "modo_reteste": false
}
```

**Success response** (topic `status`):
```json
{"tipo":"batch","evento":"configurado","ts_ms":0,"numero_op":"12345","estado":"BATCH_READY"}
```

**Failure response**:
```json
{"tipo":"rejeicao","motivo":"<code>"}
```

## END_BATCH

```json
{"cmd": "END_BATCH"}
```

**Success** (topic `status`):
```json
{"tipo":"batch","evento":"encerrado","motivo":"operador"}
```

## START_CALIBRATION

```json
{"cmd": "START_CALIBRATION"}
```

## START_ENSAIO

```json
{
  "cmd": "START_ENSAIO",
  "on_sec": 60,
  "off_sec": 60,
  "duracao_total_sec": 7200
}
```

## STOP_ENSAIO

```json
{"cmd": "STOP_ENSAIO"}
```

## OTA_UPDATE

```json
{"cmd": "OTA_UPDATE", "url": "https://..."}
```

## RESET_WIFI

```json
{"cmd": "RESET_WIFI", "clear_mqtt": false}
```

## Firmware-only commands (app não envia)

- `CANCEL_BATCH` (equivalente a END_BATCH)
- `PZEM_PROBE`
- `SET_BANCADA`
