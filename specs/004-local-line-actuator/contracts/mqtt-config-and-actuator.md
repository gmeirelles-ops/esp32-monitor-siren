# Contratos: configuração e atuador (004)

## Princípio

O **veredito não trafega como comando** cloud → device. O device publica **fato** (`tipo:teste`). Comandos cloud → device são **configuração** e **ciclo de lote**.

## Comandos (app → firmware) — existentes

Tópico: `{site}/bancada-{NN}/comando`

### `SET_BATCH` (sem breaking change)

```json
{
  "cmd": "SET_BATCH",
  "numero_op": "2026078",
  "id_produto": "072",
  "ano": "26",
  "potencia_min": 94.86,
  "potencia_max": 115.54,
  "quantidade_total": 100,
  "proximo_sequencial": 1,
  "tempo_teste_sec": 5,
  "modo_reteste": false
}
```

Firmware MUST persistir e usar nos próximos ciclos **sem** consultar Firebase.

Durante `STATE_TESTING`, `SET_BATCH` MUST ser rejeitado com motivo `config_durante_teste` (publicação em `alerta`/`rejeicao` conforme contrato existente).

## Eventos (firmware → app) — ordem garantida

Ordem interna no firmware (contrato de implementação):

1. Amostragem PZEM completa
2. `veredito` calculado
3. GPIO `relay` / `line_actuator` / LED
4. Atualização contadores NVS
5. `tipo:teste` → fila MQTT (`status`)

O app MUST NOT assumir que MQTT chega antes do movimento físico.

### `tipo:teste` (inalterado)

Ver `specs/001-fw-sw-compat/contracts/mqtt-status.md`.

## Novo: diagnóstico de atuador (opcional P2)

```json
{
  "tipo": "atuador",
  "evento": "rejeicao_pulso",
  "ts_ms": 12345678,
  "gpio": 25,
  "duracao_ms": 300
}
```

Tópico sugerido: `{site}/bancada-{NN}/status` — apenas telemetria; app pode ignorar.

## GPIO (hardware contract)

| Função | Kconfig | Comportamento |
|--------|---------|---------------|
| Carga sirene | `GPIO_RELAY` | ON durante medição |
| Refugo | `GPIO_REJECT` | Pulso em `REPROVADO` |
| Aprovação visual | `GPIO_APPROVE` | Pulso opcional em `APROVADO` |

Modo seguro em `HARDWARE_FAULT`: carga OFF; refugo OFF (ou política configurável).

## Cenário offline

Se `mqtt_bridge_is_connected() == false`:

- Passos 1–4 executam igual
- Passo 5 enfileira em `offline_queue`
- Heartbeat reporta `fila` > 0

App sincroniza quando broker volta — **sem alterar veredito**.
