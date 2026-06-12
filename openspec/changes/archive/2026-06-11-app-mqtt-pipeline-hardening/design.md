## Context

`MqttService` cria um `MqttServerClient` novo a cada `_doConnect` (reconexão com backoff 1–30s). `_onConnected` assina `updates?.listen(_handleUpdates)` sem guardar/cancelar a `StreamSubscription`; o cliente antigo é descartado com `onDisconnected` ainda apontando para o serviço — `disconnect()` no cliente antigo pode disparar `_scheduleReconnect` extra. `DevicesNotifier` escuta `service.messages` com handler `async` não aguardado. `_maybePrintLabels` engole erros. `LabelsScreen._printPending` limpa o buffer inteiro após imprimir. `devicesProvider` só nasce quando alguma tela o observa.

## Goals / Non-Goals

**Goals:**

- Garantir exatamente um listener ativo por conexão e nenhum callback órfão de clientes antigos.
- Processar mensagens MQTT em ordem, uma por vez.
- Buffer de etiquetas nunca perde entradas não impressas.
- Operador sempre fica sabendo de falha de impressão.
- MQTT ativo desde o boot do app.

**Non-Goals:**

- Refatorar o `DevicesNotifier` em serviços menores (fica para mudança própria).
- TLS/auth MQTT (depende de mudança no firmware/broker).
- Retry automático de impressão.

## Decisions

### 1. Ciclo de vida da assinatura no `MqttService`

Guardar `StreamSubscription? _updatesSub`. Em `_doConnect`, antes de criar o cliente novo:

```
_updatesSub?.cancel(); _updatesSub = null;
old.onDisconnected = null; old.onConnected = null; old.disconnect();
```

Em `_onConnected`: `_updatesSub?.cancel()` e então `_updatesSub = _client!.updates?.listen(_handleUpdates)`. Em `disconnect()`/`dispose()`: cancelar também. Isso elimina tanto o listener duplicado quanto o reconnect espúrio do cliente antigo.

### 2. Serialização das mensagens no `DevicesNotifier`

Encadear futures no listener:

```
Future<void> _pump = Future.value();
_sub = service.messages.listen((e) {
  _pump = _pump.then((_) => _handleMessage(e));
});
```

FIFO garantido sem reentrância; sem mutex/pacote extra. Erros de um handler não podem matar a cadeia → envolver `_handleMessage` em try/catch dentro do `then`.

### 3. Remoção por id na impressão manual

`_printPending` passa a operar sobre `List<LabelBufferEntry>`: imprime em blocos de 3 e acumula os **ids impressos**; ao final (ou em falha parcial), remove do buffer apenas os ids efetivamente enviados à impressora. Entradas adicionadas durante a impressão permanecem.

### 4. Sinalização de falha de impressão

Novo `printFailureProvider` (`StateProvider<String?>`). `_maybePrintLabels` seta a mensagem no catch (mantendo as etiquetas no buffer). `BatchScreen` escuta e mostra snackbar (operador está lá durante produção); `LabelsScreen` exibe banner quando há falha registrada, limpa ao imprimir com sucesso.

### 5. Bootstrap do MQTT no app

Em `_SireneAppState.initState` (mesmo `addPostFrameCallback` já usado para o sync): `ref.read(devicesProvider)` — cria o notifier, que conecta o MQTT e passa a registrar mensagens independentemente da tela inicial.

## Risks / Trade-offs

- **[Risco] Serialização atrasa procesamento sob rajada** → volume real é baixo (1 teste/ciclo por bancada); aceitável.
- **[Risco] Cancelar assinatura no cliente antigo durante corrida de reconexão** → ordem definida (cancelar antes de criar novo) e callbacks anulados tornam o caminho idempotente.
- **[Trade-off] Snackbar de impressão no Batch** acopla levemente telas, mas é onde o operador está; o estado fica num provider central, sem dependência direta.

## Migration Plan

1. `MqttService`: lifecycle da assinatura + limpeza do cliente antigo (com teste de unidade do serviço onde possível).
2. `DevicesNotifier`: fila serializada.
3. `LabelsScreen`: remoção por id.
4. `printFailureProvider` + UI.
5. `app.dart`: bootstrap.
6. `flutter analyze`/`test`.

Sem migração de dados. Rollback trivial.
