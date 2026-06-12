## Why

O número de série é `produto(3) + ano(2) + sequencial(4) + dígito ITF`, então sua unicidade depende de `(produto, ano, sequencial)` — o `numero_op` não entra no código de barras. Hoje o `proximo_sequencial` é digitado manualmente no formulário de lote (default `1`) e o firmware só mantém a contagem **dentro de um lote**. Quando o operador abre uma nova OP do mesmo produto/ano, o sequencial volta para `1` e gera **seriais duplicados** — quebra de rastreabilidade e códigos de barras repetidos em peças diferentes.

## What Changes

- Manter um contador persistente de sequencial por `(id_produto, ano)` no SQLite, atualizado a cada serial aprovado.
- Pré-preencher automaticamente `proximo_sequencial` no formulário de lote com `último + 1` ao escolher produto e ano.
- Adicionar trava anti-duplicado: antes de gerar/imprimir um serial, verificar se ele já existe localmente; se existir, não imprime e sinaliza alerta ao operador.
- Adicionar reconciliação de lote: detectar buracos (gaps) e duplicatas na sequência de seriais aprovados de uma OP / produto-ano.
- Sem alteração de firmware — o app passa a enviar o `proximo_sequencial` correto no `SET_BATCH`.

## Capabilities

### New Capabilities

- `serial-counter`: Contador persistente de sequencial por produto/ano, trava anti-duplicado e reconciliação de sequência.

### Modified Capabilities

- `batch-operator-ui`: O `proximo_sequencial` passa a ser sugerido automaticamente a partir do contador, em vez de digitado do zero.
- `serial-traceability`: A geração do serial no app passa a checar duplicidade antes de emitir etiqueta.

## Impact

- **App Flutter** (`sirene_app/`): nova tabela `SerialCounters` no Drift (schema v4, migração), métodos de banco, hook em `mqtt_providers.dart` (geração de serial), formulário em `batch_screen.dart`, novo painel de reconciliação.
- **Firmware ESP32**: nenhuma alteração.
- **Firestore**: nenhuma alteração de schema; contador é local (fonte de verdade no posto).
