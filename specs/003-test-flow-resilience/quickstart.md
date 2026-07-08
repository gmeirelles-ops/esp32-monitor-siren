# Quickstart: Validação 003-test-flow-resilience

## Pré-requisitos

- App Windows com mudanças 003 (`flutter test` verde)
- Firmware ≥ 1.7.6 com `telemetry_publish_now` no ciclo de teste
- Bancada ESP32 + broker MQTT acessível
- OP de teste (ex.: `00002`, produto `072`, qtd 2, tempo 15s)

## Cenário 1 — Rede lenta, 3 reprovados mesmo sequencial

1. Throttle MQTT no broker ou firewall (latência 5–30s por mensagem).
2. SET_BATCH na bancada.
3. Pressionar botão 3× seguidas (reprovar na bancada).
4. **Esperado**: painel operador mostra "Testando…" durante cada ciclo; após cada teste, "Aguardando MQTT" se resultado atrasar; **3 linhas** no histórico com mesmo `sequencial` e `ts_ms` distintos.

## Cenário 2 — Fila offline

1. Desconectar broker ou Wi-Fi da bancada.
2. Executar 2 testes (LED/buzzer na bancada).
3. Verificar `fila` > 0 no heartbeat (strip operador).
4. Reconectar broker.
5. **Esperado**: fila drena; app grava exatamente 2 testes (sem duplicata por replay `ts_ms`).

## Cenário 3 — Aprovação com impressora lenta

1. Configurar impressora com delay ou desligada temporariamente.
2. Aprovar 1 sirene.
3. **Esperado**: hero APROVADO aparece **antes** da etiqueta; buffer de impressão processa depois.

## Comandos úteis

```powershell
cd c:\dev\diponto-sirene\sirene_app
flutter test test\test_dedupe_ts_ms_test.dart test\mqtt_parser_test.dart test\firestore_mappers_test.dart
```

## Registro

Documentar resultado em `specs/002-e2e-health-audit/bench-results.md` (seção 003).
