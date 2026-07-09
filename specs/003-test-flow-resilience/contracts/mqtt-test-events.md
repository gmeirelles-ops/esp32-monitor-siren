# MQTT Test Events Contract

Tópico: `{site}/bancada-{NN}/status`

## tipo:teste (resultado)

```json
{
  "tipo": "teste",
  "ts_ms": 6886992,
  "ts_unix": 1783453590,
  "numero_op": "00002",
  "id_produto": "072",
  "ano": "26",
  "veredito": "APROVADO",
  "potencia_media": 39.58,
  "sequencial": 500,
  "aprovados_no_lote": 1
}
```

| Campo | Tipo | Obrigatório | Notas |
|-------|------|-------------|-------|
| ts_ms | int | sim (firmware ≥1.7.5) | Chave de dedupe no app |
| ts_unix | int | não | Reforço de unicidade |
| veredito | string | sim | APROVADO ou REPROVADO |
| sequencial | int | sim | Não incrementa em REPROVADO |

## Dedupe (app)

- Ignorar mensagem se `(numero_op, ts_ms)` já gravado (canônico — spec 006).
- Replay da fila offline: mesmo `ts_ms` → descartar.
- Legado sem `ts_ms`: `(numero_op, sequencial, veredito, potencia_media)`.

## Heartbeat (transições)

Publicado em `{site}/bancada-{NN}/heartbeat` imediatamente ao:
- entrar `TESTING`
- concluir teste (`BATCH_READY`)

Intervalo periódico: 30s (inalterado).

## Referências

- [`specs/001-fw-sw-compat/contracts/mqtt-status.md`](../../001-fw-sw-compat/contracts/mqtt-status.md)
