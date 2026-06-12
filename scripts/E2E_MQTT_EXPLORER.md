# Verificação E2E via MQTT Explorer

Conecte o **MQTT Explorer** ao broker e deixe o **app Flutter aberto** na mesma rede.

## Conexão

| Campo | Valor |
|-------|--------|
| Host | `192.168.51.87` |
| Port | `1883` |
| Protocol | MQTT v3.1.1 |
| User / Password | (vazio) |

## Assinar (para ver o que o app também vê)

Adicione estas assinaturas wildcard:

- `sirene/+/heartbeat`
- `sirene/+/status`
- `sirene/+/presenca`

Substitua `DEVICE_ID` pelo MAC do ESP32 em hex (12 caracteres), ex.: `aabbccddeeff`.

---

## Ordem dos passos

### 0. Antes — no app

1. **Produtos** → cadastre ID `123`, nome `Sirene teste E2E 20W`, ref 20 W, min 18, max 22 W.
2. **Configurações** → broker `192.168.51.87:1883`, `station_id` = `posto-D1`.
3. (Windows) Nuvem → login `operador.teste@diponto.com.br` / `SireneTeste2026!` → sync ON.

---

### 1. SET_BATCH

**Publicar em:**

```
sirene/aabbccddeeff/comando
```

**Payload (JSON, uma linha):**

```json
{"cmd":"SET_BATCH","numero_op":"2026099","id_produto":"123","ano":"26","tempo_teste":5,"potencia_min":18.0,"potencia_max":22.0,"quantidade_total":10,"proximo_sequencial":1}
```

No app: dispositivo deve ir para **Lote pronto** (se ESP32 real estiver na rede).  
Só com app + Explorer (sem ESP32): pule para o passo 3 — o app processa `status` e `heartbeat` direto.

---

### 2. Heartbeat (dispositivo online)

**Publicar em:**

```
sirene/aabbccddeeff/heartbeat
```

**Payload:**

```json
{"uptime":3600,"rssi":-58,"estado":"BATCH_READY","fila":0,"firmware_version":"1.3.0"}
```

No app: dispositivo aparece em **Dispositivos**, estado *Lote pronto*.

---

### 3. Resultado de teste (principal)

**Publicar em:**

```
sirene/aabbccddeeff/status
```

**Payload:**

```json
{"tipo":"teste","numero_op":"2026099","id_produto":"123","ano":"26","veredito":"APROVADO","potencia_media":20.12,"sequencial":1,"aprovados_no_lote":1}
```

No app:

- Último teste **APROVADO** no dispositivo
- Serial gerado (se aprovado)
- Gravado no SQLite local
- (Windows + sync) enfileira `test_results/2026099_1`

---

### 4. (Opcional) Presença offline/online

**Publicar em** `sirene/aabbccddeeff/presenca`:

- `online` — dispositivo online
- `offline` — dispositivo offline (LWT)

---

### 5. END_BATCH (opcional)

**Publicar em** `sirene/aabbccddeeff/comando`:

```json
{"cmd":"END_BATCH"}
```

---

## Conferir Firestore (Windows + sync)

https://console.firebase.google.com/project/monitor-sirenv2-6d201/firestore

| Coleção | Documento esperado |
|---------|-------------------|
| `products` | `123` |
| `test_results` | `2026099_1` |
| `devices` | `aabbccddeeff` (até 60 s após heartbeat) |
| `batches` | `2026099` (se SET_BATCH foi pelo app) |

## Operador de teste

| Campo | Valor |
|-------|--------|
| E-mail | `operador.teste@diponto.com.br` |
| Senha | `SireneTeste2026!` |
