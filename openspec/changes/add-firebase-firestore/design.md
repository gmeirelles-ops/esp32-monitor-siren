## Context

O ecossistema Diponto Sirene Validator opera assim:

```
ESP32 ──MQTT (LAN)──► Mosquitto ──► App Flutter (Windows) ──► SQLite local
```

O firmware **não** se conecta à internet nem ao Firebase — decisão arquitetural intencional (operação offline na linha, MQTT cobre tempo real na VLAN). O app Flutter já:

- Descobre dispositivos via `sirene/+/heartbeat` e `presenca`
- Persiste resultados de teste, buffer de etiquetas e catálogo de produtos em **Drift/SQLite**
- Gera seriais ITF 2 de 5 e imprime etiquetas Zebra

A documentação (`GUIA_COMPLETO.md` §16) já define o esquema Firestore alvo e a topologia `App → Firestore`. Esta change implementa essa fase 2 sem alterar contratos MQTT nem firmware.

### Restrições

- Posto de produção pode ficar sem internet por horas — sync **não pode bloquear** operação local.
- Windows desktop é a plataforma primária de produção.
- Múltiplos postos podem gravar no mesmo projeto Firebase — idempotência é obrigatória.

## Goals / Non-Goals

**Goals:**

- Persistência centralizada de resultados de teste, lotes, dispositivos e catálogo de produtos.
- Sincronização assíncrona, tolerante a falhas, com fila local de pendências.
- Autenticação de operadores para proteger gravações no Firestore.
- Zero impacto na latência MQTT e no fluxo de teste/etiqueta quando offline.
- Setup reproduzível via FlutterFire CLI + arquivos versionados (`firestore.rules`, índices).

**Non-Goals:**

- Conectar ESP32 diretamente ao Firebase.
- Substituir SQLite por Firestore como storage primário no posto.
- Cloud Functions, BigQuery ou dashboards web (podem vir em change futura).
- Sincronização bidireta de catálogo de produtos (nuvem → local) na v1 — apenas upload local → nuvem.
- Firebase Realtime Database, Remote Config ou Crashlytics nesta change.
- MQTT TLS ou autenticação de broker (change separada de hardening).

## Decisions

### Decisão 1: Padrão offline-first com SQLite como source of truth

O app grava **sempre** no SQLite primeiro (comportamento atual inalterado). Um `FirestoreSyncService` observa eventos de domínio e enfileira operações de upsert no Firestore.

```
MQTT event → SQLite (sync) → SyncQueue (async) → Firestore (when online + authed)
```

- *Alternativa A*: Firestore como primário com persistence habilitada — descartada porque o app já tem schema Drift maduro e depende de queries locais para etiquetas/histórico.
- *Alternativa B*: Backend intermediário (Cloud Functions + MQTT bridge) — descartada por complexidade operacional; o app já tem todos os dados.

### Decisão 2: Fila de sincronização em SQLite

Nova tabela `SyncQueue` no Drift:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | int PK | Auto-increment |
| `collection` | text | `devices`, `test_results`, `batches`, `products` |
| `document_id` | text | ID do documento Firestore |
| `payload` | text | JSON serializado |
| `operation` | text | `set` ou `merge` |
| `created_at` | datetime | Timestamp de enfileiramento |
| `attempts` | int | Contador de retries |
| `last_error` | text? | Último erro |

Worker periódico (timer 30 s + trigger em reconexão de rede) drena a fila com backoff exponencial (máx 5 tentativas, depois marca como falha permanente visível em Configurações).

### Decisão 3: Modelo de dados Firestore

#### `devices/{device_id}`

```json
{
  "device_id": "aabbccddeeff",
  "firmware_version": "1.2.0",
  "last_seen": "Timestamp",
  "estado": "BATCH_READY",
  "online": true,
  "rssi": -62,
  "fila_offline": 0,
  "updated_by_station": "posto-01"
}
```

Document ID = `device_id` (MAC sem separadores). Upsert em cada heartbeat; `online: false` ao receber LWT `presenca: offline`.

#### `test_results/{numero_op}_{sequencial}`

```json
{
  "device_id": "aabbccddeeff",
  "numero_op": "2026001",
  "id_produto": "123",
  "ano": "26",
  "veredito": "APROVADO",
  "potencia_media": 20.15,
  "sequencial": 1,
  "aprovados_no_lote": 1,
  "serial": "1232600018",
  "timestamp": "Timestamp",
  "station_id": "posto-01"
}
```

Chave composta garante idempotência — reprocessar o mesmo teste não cria duplicata.

#### `batches/{numero_op}`

```json
{
  "numero_op": "2026001",
  "id_produto": "123",
  "ano": "26",
  "quantidade_total": 10,
  "aprovados": 3,
  "device_id": "aabbccddeeff",
  "started_at": "Timestamp",
  "ended_at": "Timestamp | null",
  "status": "active | completed",
  "station_id": "posto-01"
}
```

Criado/atualizado em `SET_BATCH`; `status: completed` e `ended_at` em `END_BATCH`.

#### `products/{id_produto}`

```json
{
  "id_produto": "123",
  "nome": "Sirene 20W",
  "potencia_ref": 20.0,
  "potencia_min": 18.0,
  "potencia_max": 22.0,
  "tolerancia_pct": 10.0,
  "tempo_teste_sec": 5,
  "calibrado_em": "Timestamp | null",
  "calibrado_device_id": "aabbccddeeff | null",
  "updated_at": "Timestamp"
}
```

Upload em create/update/recalibração de produto (não download na v1).

### Decisão 4: Identificação do posto (`station_id`)

`station_id` lido de `SharedPreferences` (configurável em Configurações, padrão hostname da máquina ou `posto-01`). Permite filtrar dados por estação no Console e em queries futuras.

### Decisão 5: Firebase Auth com e-mail/senha

- Login obrigatório para habilitar sync (toggle desabilitado sem sessão).
- Sessão persistida localmente pelo SDK (`setPersistence` padrão).
- Contas criadas manualmente no Firebase Console (sem auto-registro na v1).
- Tela de login simples: e-mail, senha, botão entrar; logout em Configurações.

*Alternativa*: Anonymous auth — descartada por não permitir auditoria por operador.

### Decisão 6: Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }
    match /devices/{deviceId} {
      allow read, write: if isAuthenticated();
    }
    match /test_results/{resultId} {
      allow read, write: if isAuthenticated();
    }
    match /batches/{batchId} {
      allow read, write: if isAuthenticated();
    }
    match /products/{productId} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

Regras permissivas para usuários autenticados — adequado para rede de fábrica com contas controladas. Refinamento por `custom claims` (admin vs operador) fica para change futura.

### Decisão 7: Estrutura de código no app

```
sirene_app/lib/features/cloud/
├── firebase_bootstrap.dart      # init Firebase + providers
├── auth/
│   ├── auth_service.dart
│   ├── auth_providers.dart
│   └── login_screen.dart
├── sync/
│   ├── firestore_sync_service.dart
│   ├── sync_queue_processor.dart
│   └── sync_providers.dart
└── models/
    └── firestore_mappers.dart   # Drift/MQTT → Firestore maps
```

Hooks mínimos nos pontos existentes:

- `mqtt_providers.dart` → após `insertTestResult`, chamar `syncService.enqueueTestResult(...)`
- `mqtt_providers.dart` → em heartbeat, chamar `syncService.enqueueDeviceUpdate(...)`
- `mqtt_providers.dart` → em `setActiveBatch`/`endBatch`, chamar `syncService.enqueueBatch(...)`
- `products_provider.dart` → após upsert, chamar `syncService.enqueueProduct(...)`

### Decisão 8: Dependências Flutter

```yaml
firebase_core: ^3.12.1
cloud_firestore: ^5.6.5
firebase_auth: ^5.5.1
```

Geradas via `flutterfire configure` com `firebase_options.dart` commitado (padrão FlutterFire para apps de fábrica com projeto dedicado).

### Decisão 9: Firestore edition e região

- **Edition**: Firestore Standard (suficiente para documentos pequenos, queries simples, custo previsível).
- **Região**: `southamerica-east1` (São Paulo) — menor latência para fábrica brasileira.
- **Database ID**: `(default)`.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Internet instável na fábrica | Fila SQLite + sync assíncrono; operação local inalterada |
| Duplicata de test_results | Chave `numero_op_sequencial` como document ID |
| Credenciais Firebase no binário | Auth + Rules; projeto Firebase dedicado à produção |
| Sync atrasado gera visão desatualizada no Console | Aceitável — Console é monitoramento, não controle em tempo real |
| Windows sem suporte nativo a alguns plugins Firebase | Validar `flutter build windows` cedo; Firebase C++ SDK suporta desktop |
| Custo Firestore com muitos heartbeats | Throttle: gravar `devices` no máximo a cada 60 s por device_id (debounce) |
| Operador esquece login | Sync desabilitado por padrão até primeiro login; indicador claro na UI |

## Migration Plan

1. Criar projeto Firebase `diponto-sirene` (ou nome acordado) no Console.
2. Ativar Firestore Standard em `southamerica-east1`.
3. Rodar `flutterfire configure` no `sirene_app/`.
4. Deploy de rules e índices: `firebase deploy --only firestore`.
5. Criar contas de operador no Console.
6. Release do app com sync **desabilitado por padrão**; habilitar por posto após validação.
7. Rollback: desabilitar toggle de sync nas Configurações — app volta a operar só com SQLite, sem remover dados locais.

## Open Questions

- Nome final do projeto Firebase e domínio de e-mail dos operadores (`@diponto.com.br`?).
- Se múltiplas fábricas compartilham o mesmo projeto ou projetos isolados por unidade.
- Política de retenção de `test_results` (TTL automático vs arquivo manual).
