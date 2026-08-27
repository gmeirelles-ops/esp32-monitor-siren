## Context

Regras atuais: `allow read, write: if isAuthenticated()` em todas as coleções.

O app usa upsert idempotente em `test_results/{numero_op}_{sequencial}`, merge em `devices` e `products`, e create/update em `batches`.

## Goals / Non-Goals

**Goals:**
- Impedir delete de resultados de teste por operadores.
- Garantir que writes incluam campos de rastreabilidade.
- Manter operação do posto sem bloquear sync legítimo.

**Non-Goals:**
- App Check / attestation de dispositivo.
- Criptografia em repouso (gerenciada pelo Firebase).
- MQTT security (change `mqtt-tls-auth`).

## Decisions

### 1. Imutabilidade de test_results

**Decisão:** `allow create` e `allow update` apenas se `!exists` ou merge idempotente com mesmos `numero_op`+`sequencial`; `allow delete: if false` para não-admin.

**Alternativa:** só `create` — o app já faz set/merge; update com mesmos campos é aceitável.

### 2. Papéis via custom claims (fase 2)

**Decisão v1:** autenticado pode read all; write restrito por coleção. v2 adiciona `request.auth.token.role == 'admin'` para delete de products e gestão de usuários.

### 3. Validação de station_id

**Decisão:** writes em `test_results` e `batches` exigem `station_id` string não vazia.

### 4. Emulator tests

**Decisão:** `scripts/test_firestore_rules.sh` com `@firebase/rules-unit-testing` ou emulator + casos documentados.

## Risks / Trade-offs

- **[Regras quebram sync existente]** → rodar suite contra payloads reais do `firestore_mappers.dart`.
- **[Sem claims na v1, todos autenticados são iguais]** → documentar como passo 2.

## Migration Plan

1. Deploy regras em staging/emulator.
2. Validar sync do app Windows com conta de teste.
3. `firebase deploy --only firestore:rules` em produção.
4. Monitorar rejeições no Console.

## Open Questions

- Adotar custom claims já na v1 ou apenas restrições por coleção?
