## Why

Em um lote com meta de 10 peças, quando 4 sirenes são aprovadas o operador espera **4 seriais distintos e sequenciais** no buffer de etiquetas (ex.: seq 1, 2, 3, 4). Hoje apenas 1 etiqueta aparece pendente porque o simulador de desenvolvimento e o estado local do lote **reutilizam o mesmo `proximo_sequencial`** inicial — aprovações subsequentes colidem no anti-duplicado e não entram no buffer.

## What Changes

- Calcular o sequencial de cada aprovação como `proximo_sequencial_inicial + aprovados_ja_emitidos_no_lote`, alinhado ao firmware ESP32.
- Atualizar `activeBatch.proximoSequencial` no app após cada aprovação com serial emitido.
- Corrigir `simulateTestResult` para incrementar sequencial como o hardware faria.
- Exibir seriais emitidos por OP no Batch Live Dashboard e na tela Etiquetas (lista completa, não só contador).
- Testes cobrindo 4 aprovações consecutivas gerando 4 seriais únicos no buffer.

## Capabilities

### New Capabilities

_(nenhuma — correção em capacidades existentes)_

### Modified Capabilities

- `serial-counter`: Sequencial de emissão avança a cada aprovação dentro do lote ativo.
- `serial-and-labels`: N aprovações no lote produzem N seriais distintos no buffer (até a meta).
- `batch-dev-simulator`: Simulador usa sequencial incremental coerente com o firmware.
- `batch-live-dashboard`: Lista de seriais emitidos na OP corrente.

## Impact

- **App**: `mqtt_providers.dart` (`processTestResult`, `simulateTestResult`), `BatchConfig` / `DeviceInfo`, `batch_live_screen.dart`, `labels_screen.dart`.
- **Firmware**: sem alteração (já incrementa `proximo_sequencial` por aprovação).
- **SQLite**: sem migração; usa contadores e buffer existentes.
