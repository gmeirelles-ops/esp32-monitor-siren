# Quickstart: Validação 006-batch-duplicate-sequence

## Pré-requisitos

- Bancada com firmware ≥ versão com 006
- App Windows com MQTT conectado ao broker de produção/staging
- PZEM funcional (ou aceitar HARDWARE_FAULT apenas em testes de UI)

## Cenário 1 — Bloqueio reteste (FR-004)

1. Cadastrar lote de 10 peças
2. Aprovar 1 peça
3. Em menos de 5 s, pressionar botão na **mesma** peça
4. **Esperado**: OLED/firmware rejeita; app mostra "peça já aprovada"; sequencial não avança de novo

## Cenário 2 — Novo lote limpo (FR-006)

1. Encerrar lote com 5 aprovados (OP `00002`)
2. Cadastrar novo lote com **mesma OP**
3. **Esperado**: `aprovados=0`, `proximo_sequencial=1` no painel e heartbeat

## Cenário 3 — MQTT instável (FR-007)

1. Lote ativo com 3 aprovados
2. Desconectar Wi-Fi do ESP por ~60 s
3. Aprovar 2 peças (confiar no OLED)
4. Reconectar Wi-Fi
5. **Esperado**: em ≤10 s, painel mostra 5 aprovados, sequencial correto, seriais sincronizados

## Cenário 4 — Sequencial e reprovações (FR-002, FR-003)

1. Reprovar 2× no sequencial N
2. Aprovar no sequencial N
3. **Esperado**: próximo sequencial = N+1; total aprovados = 1 para essa peça

## Cenário 5 — Encerrar lote com MQTT down (R02 / Sprint A)

1. Lote ativo com MQTT conectado
2. Desconectar broker ou Wi-Fi do **PC do app** (bancada pode continuar online)
3. No app, tentar **Encerrar lote**
4. **Esperado**: mensagem "MQTT desconectado"; lote permanece ativo no app e no firmware

## Cenário 6 — Encerrar lote no firmware (R03 / Sprint A)

1. Lote ativo com sync habilitado
2. Encerrar lote pela bancada (MQTT `encerrado` ou fluxo físico equivalente)
3. **Esperado**: app limpa lote ativo, OP locked no SQLite, batch `completed` na fila Firestore

## Cenário 7 — Firmware 1.8.6 em campo

1. Gravar `sirene-validator.bin` ≥ 1.8.6 via USB ou OTA
2. Confirmar no heartbeat: `firmware_version` = `1.8.6`
3. Aprovar 1 peça e verificar ordem NVS → GPIO (sem pulso se simular falha NVS em bancada de dev)

## Registro de validação

Preencher resultados em [bench-validation.md](bench-validation.md).

## Comandos CI

```bash
cd sirene_app && flutter test
cd sirene-validator/host_tests && cmake -B build && cmake --build build && ctest --test-dir build
```
