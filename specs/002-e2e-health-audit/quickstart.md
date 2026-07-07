# Quickstart: Auditoria ponta a ponta — Diponto Sirene

Guia unificado para validar o fluxo completo de produção. Referência: [spec.md](./spec.md).

## Pré-requisitos

- Firmware **1.7.5** flashado na bancada
- App `sirene_app` atualizado no posto Windows
- Broker MQTT acessível
- Operador com PIN cadastrado
- Produto cadastrado (ex.: 072, limites 35.62–43.54 W)
- Impressora Zebra **ou** laser Diatu configurado
- Firebase login + sync ON (Windows)

Variáveis de exemplo:
- Site: `producao`
- Bancada: `03` → tópico base `producao/bancada-03/`

---

## Fase A — Pré-requisitos posto

| # | Verificação | OK? |
|---|-------------|-----|
| A1 | Broker MQTT responde | |
| A2 | Bancada online (heartbeat `presenca: online`) | |
| A3 | App abre no Windows (CPU SSE4.1) | |
| A4 | Operador logado via PIN | |
| A5 | Produto 072 cadastrado com limites corretos | |
| A6 | Modo marcação (Zebra ou laser) configurado | |
| A7 | Sync cloud ativo (Windows) | |

---

## Fase B — MQTT + lote

1. Iniciar lote no app (OP `0001`, produto `072`, qtd 108, seq 500).
2. Inspecionar publicação em `producao/bancada-NN/comando`:

```json
{"cmd":"SET_BATCH","numero_op":"0001","id_produto":"072","ano":"26","tempo_teste":10,"potencia_min":35.62,"potencia_max":43.54,"quantidade_total":108,"proximo_sequencial":500,"modo_reteste":false}
```

3. Confirmar ACK ou heartbeat `estado: BATCH_READY`.
4. Verificar heartbeat `firmware_version: 1.7.5` e **`fila: 0`**.

| # | Verificação | OK? |
|---|-------------|-----|
| B1 | SET_BATCH aceito sem rejeição | |
| B2 | Estado BATCH_READY | |
| B3 | firmware_version 1.7.5 | |
| B4 | fila = 0 antes do teste | |

---

## Fase C — Teste físico

1. Pressionar botão **uma vez**.
2. Aguardar `tempo_teste` segundos (10 s para produto 072).
3. Verificar **exatamente 1** mensagem `tipo:teste` no MQTT.
4. Confirmar veredito APROVADO ou REPROVADO na UI.

| # | Verificação | OK? |
|---|-------------|-----|
| C1 | 1 toque → 1 teste no painel | |
| C2 | Veredito claro (não vazio) | |
| C3 | sequencial = 500 (primeiro teste) | |
| C4 | Segundo toque → sequencial 501 | |

---

## Fase D — Serial + marcação

| # | Verificação | OK? |
|---|-------------|-----|
| D1 | Serial ITF 10 dígitos gerado (se APROVADO) | |
| D2 | Etiqueta impressa ou laser enfileirado | |
| D3 | Modo reteste: sem serial | |

---

## Fase E — Cloud (Windows + sync)

| # | Verificação | OK? |
|---|-------------|-----|
| E1 | `test_results/0001` status active | |
| E2 | `test_results/0001/seriais/{serial}` criado | |
| E3 | `devices/{device_id}` atualizado | |
| E4 | Sync pendentes = 0 | |

Console: https://console.firebase.google.com/project/monitor-sirenv2-6d201/firestore

---

## Fase F — Automação local

```bash
./scripts/ci_local.sh
```

```bash
cd sirene_app
flutter test test/mqtt_parser_test.dart test/mqtt_status_parser_test.dart test/batch_set_batch_contract_test.dart
```

| # | Verificação | OK? |
|---|-------------|-----|
| F1 | ci_local.sh passa | |
| F2 | Testes MQTT passam | |

---

## Simulação MQTT (sem ESP32)

Ver [scripts/E2E_MQTT_EXPLORER.md](../../scripts/E2E_MQTT_EXPLORER.md) ou:

```bash
MQTT_SITE=producao BANCADA=03 BROKER=192.168.51.87 ./scripts/e2e_verificacao_completa.sh
```

---

## Registrar resultados

Preencher [bench-results.md](./bench-results.md) após execução na bancada.
