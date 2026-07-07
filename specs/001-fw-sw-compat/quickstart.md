# Quickstart: Validação de Compatibilidade Firmware × App

Guia para verificar que firmware e software estão alinhados antes de liberar produção.

## Pré-requisitos

- Firmware `sirene-validator` v1.7.5+ flashado na bancada
- App `sirene_app` compilado (com fix de parser MQTT colado)
- Broker MQTT acessível (padrão: `wss://mqtt.diponto.com:443`)
- Produto cadastrado com potência de referência e tolerância
- MQTT Explorer ou `mosquitto_sub` para inspeção (opcional)

## 1. Verificar tópicos

```bash
# Substituir site e bancada
mosquitto_sub -h <broker> -t 'producao/bancada-03/#' -v
```

**Esperado**: mensagens em `presenca`, `heartbeat`, `status`, etc. — **não** em `sirene/<mac>/...`.

## 2. Testes unitários do parser (app)

```bash
cd sirene_app
flutter test test/mqtt_parser_test.dart test/mqtt_status_parser_test.dart test/mqtt_topics_test.dart
```

**Esperado**: todos passam, incluindo teste de payload colado com `ano` recuperado.

## 3. Testes unitários do firmware (host)

```bash
cd sirene-validator/host_tests
cmake -B build && cmake --build build && ctest --test-dir build
```

**Esperado**: `test_verdict`, `test_batch_quota` passam (lógica de aprovação e cota).

## 4. Cenário E2E — lote e aprovação

1. Abrir app → conectar MQTT → selecionar bancada online (`heartbeat` com `estado: IDLE` ou `BATCH_READY`).
2. Iniciar lote com produto válido.
3. Inspecionar comando publicado em `producao/bancada-NN/comando`:
   - Campos `SET_BATCH` conforme `contracts/mqtt-commands.md`.
4. Verificar heartbeat: `estado` → `BATCH_READY`.
5. Pressionar botão físico com carga na faixa de potência.
6. Verificar publicação em `status`:
   - `tipo: teste`, `veredito: APROVADO`, `sequencial` coerente.
7. No app:
   - Teste aparece no dashboard do lote.
   - Serial ITF 10 dígitos gerado (se não reteste).
   - Contador local incrementado.

**Falha comum**: passo 7 não ocorre mas passo 6 sim → problema de parser MQTT (ver `research.md` R5).

## 5. Cenário — reprovação

1. Testar com carga fora da faixa (`potencia_media` fora de min/max).
2. **Esperado**: `veredito: REPROVADO`, sem serial, sem bump de contador.

## 6. Cenário — cota cheia

1. Configurar `quantidade_total: 1`.
2. Aprovar 1 teste.
3. Tentar segundo teste.
4. **Esperado firmware**: `rejeicao` com `motivo: lote_cheio`.
5. **Esperado app**: mensagem de rejeição visível.

## 7. Cenário — modo reteste

1. Ativar reteste no app (reenvia SET_BATCH com `modo_reteste: true`).
2. Aprovar teste.
3. **Esperado**: sem serial; `aprovados_no_lote` inalterado no firmware.

## 8. Checklist de compatibilidade rápida

| # | Verificação | OK? |
|---|-------------|-----|
| 1 | Tópicos `bancada-NN` | |
| 2 | SET_BATCH aceito sem rejeição | |
| 3 | APROVADO gera serial no app | |
| 4 | REPROVADO não gera serial | |
| 5 | Parser recupera JSON colado | |
| 6 | `lote_cheio` exibido | |
| 7 | Reteste sem serial | |
| 8 | Calibração 5s publica `potencia_media` | |

## Referências

- Modelo de dados: `data-model.md`
- Comandos: `contracts/mqtt-commands.md`
- Status: `contracts/mqtt-status.md`
- Análise completa: `research.md`
