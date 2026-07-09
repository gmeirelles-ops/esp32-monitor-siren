# MQTT Contract: SET_BATCH reset (006)

## Comando SET_BATCH

Tópico: `{site}/bancada-{NN}/cmd`

```json
{
  "cmd": "SET_BATCH",
  "numero_op": "00002",
  "id_produto": "072",
  "ano": "26",
  "tempo_teste": 10,
  "potencia_min": 15.0,
  "potencia_max": 45.0,
  "quantidade_total": 100,
  "proximo_sequencial": 1,
  "modo_reteste": false
}
```

## Semântica (006 FR-006)

- **Sempre** zera `aprovados` para **0** no firmware, independente de `numero_op` anterior.
- `proximo_sequencial` vem **do payload** (app envia `sequencialInicial` do produto ou 1).
- Limpa `ultimo_veredito` no heartbeat subsequente.
- Histórico SQLite no app **não** é apagado; apenas estado volátil da sessão.

## ACK

`{"tipo":"batch","evento":"configurado",...}` em `/status`

## Heartbeat após SET_BATCH

```json
{
  "aprovados": 0,
  "proximo_sequencial": 1,
  "ultimo_veredito": ""
}
```
