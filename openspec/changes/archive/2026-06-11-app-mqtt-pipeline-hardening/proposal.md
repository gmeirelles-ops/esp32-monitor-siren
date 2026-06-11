## Why

Uma análise completa do app encontrou cinco riscos críticos/importantes concentrados no pipeline MQTT → banco → etiquetas:

1. **Listeners duplicados na reconexão.** `MqttService._onConnected` chama `updates?.listen(...)` a cada conexão sem cancelar a assinatura anterior, e o cliente antigo é descartado com callbacks ainda registrados. Risco: mensagens processadas em dobro (inserções duplicadas, serial consumido duas vezes) e ciclos espúrios de reconexão.
2. **Processamento concorrente de mensagens.** `DevicesNotifier._handleMessage` é `async` e o `listen` não aguarda; duas aprovações próximas podem intercalar `serialExists` → `bumpSerialCounter` → `addLabelToBuffer` e corromper a alocação de serial.
3. **Impressão manual apaga o buffer inteiro.** `LabelsScreen._printPending` remove **todas** as entradas do buffer após imprimir, não apenas as impressas — aprovação que chega durante a impressão perde a etiqueta.
4. **Falha de impressora silenciosa.** O auto-print engole exceções (`catch (_) {}`); o operador acredita que as etiquetas saíram.
5. **MQTT só inicia ao abrir certas telas.** `devicesProvider` é lazy; se o app abre no Painel/Produtos/Etiquetas, heartbeats e resultados de teste não são registrados até alguém visitar Dispositivos/Lote.

## What Changes

- Gerenciar o ciclo de vida da assinatura MQTT: cancelar a assinatura anterior e limpar callbacks do cliente antigo antes de criar um novo.
- Serializar o processamento de mensagens no `DevicesNotifier` (fila FIFO de futures) para eliminar corridas na geração de serial.
- Impressão manual remove do buffer **somente** as entradas efetivamente impressas (por id).
- Falha de impressão (automática ou manual) sinalizada ao operador via provider + snackbar e visível na tela de Etiquetas.
- Inicializar o pipeline MQTT na inicialização do app (`app.dart`), independente da tela inicial.

## Capabilities

### Modified Capabilities

- `mqtt-client`: ciclo de vida único do listener por conexão e processamento serializado de mensagens.
- `label-printing`: remoção apenas das etiquetas impressas e sinalização de falha de impressão.
- `flutter-app-shell`: pipeline MQTT ativo desde a inicialização do app.

## Impact

- **App Flutter** (`sirene_app/`): `mqtt_service.dart` (assinatura/cliente), `mqtt_providers.dart` (serialização, alerta de impressão), `labels_screen.dart` (remoção por id, feedback), `app.dart` (bootstrap do `devicesProvider`).
- **Firmware ESP32**: nenhuma alteração.
- **Firestore**: nenhuma alteração.
