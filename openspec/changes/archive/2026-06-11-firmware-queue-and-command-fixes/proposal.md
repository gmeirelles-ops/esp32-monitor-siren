## Why

O firmware `sirene-validator` já opera em chão de fábrica, mas quatro falhas de robustez ainda comprometem rastreabilidade e controle de lote: alertas e calibração enfileirados offline são republicados no tópico errado; comandos MQTT destrutivos enfileirados durante testes longos podem ser aplicados depois; leituras PZEM abortam o ciclo inteiro na primeira falha UART; e `quantidade_total` é persistido mas não impede testes além da meta. Corrigir isso agora reduz perda de dados e comportamento imprevisível sem alterar o app Flutter.

## What Changes

- Fila offline passa a persistir o sufixo de tópico MQTT (`status`, `alerta`, `calibracao`) junto com cada mensagem e a republicar no tópico correto ao drenar.
- Comandos MQTT sensíveis a estado (`SET_BATCH`, `END_BATCH`, `START_CALIBRATION`, `OTA_UPDATE`) são rejeitados na chegada quando o dispositivo está em teste ou calibração, em vez de serem enfileirados para execução tardia.
- Ciclo PZEM tolera falhas transitórias de UART com retentativas por amostra antes de descartar a leitura ou falhar o ciclo.
- Meta de lote (`quantidade_total`) bloqueia novo teste pelo botão quando `aprovados >= quantidade_total` (com `quantidade_total > 0`), com feedback local e rejeição publicável.
- Testes host-based para a lógica nova (cota de lote e guards de comando), sem mudanças no app Flutter.

## Capabilities

### New Capabilities

_(nenhuma — correções estendem specs existentes)_

### Modified Capabilities

- `offline-resilience`: sincronização FIFO preserva o tópico de origem de cada mensagem enfileirada.
- `batch-test-execution`: aplica `quantidade_total` como limite operacional; endurece tolerância a falhas PZEM por amostra.
- `mqtt-messaging`: rejeição imediata de comandos destrutivos recebidos durante teste ou calibração (comando obsoleto não executado após o ciclo).

## Impact

- **Firmware**: `offline_queue` (API push/peek, formato SPIFFS, drain), `main.c` (`publish_or_queue`, `on_mqtt_command`, `run_test_cycle`), `pzem.c` (`pzem_measure_cycle`), `pure_logic` (helper de cota de lote).
- **Host tests**: novos casos em `sirene-validator/host_tests/`.
- **Contratos MQTT**: mensagens de rejeição adicionais (`lote_cheio`, `cmd_durante_teste`); sem mudança de payload de `SET_BATCH`.
- **App Flutter / Firestore**: sem alteração; consumidores já assinam tópicos separados e beneficiam-se da rota correta offline.
- **SPIFFS**: entradas antigas da fila (só JSON) tratadas como tópico `status` por compatibilidade.
